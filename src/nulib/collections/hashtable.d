/**
    NuLib HashTable

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:
        Luna Nielsen
*/
module nulib.collections.hashtable;
import numem;

/**
    The maximum load on a hash table before it must grow.
*/
enum HASH_TABLE_MAX_LOAD = 0.75;

/**
    The increments a hash table will grow by.
*/
enum HASH_TABLE_GROW_INCREMENTS = 64;

/**
    A open-addressing hash table implementation for quick
    cache friendly key-value lookups.

    The hash table makes copies of the keys within it, but values
    are not owned by it, as such values need to have lifetimes longer
    than the hash table.
*/
struct HashTable(TKey, TValue, alias hashfn=fnv1a_hash!(size_t, TKey)) {
private:
@nogc:
    TEntry[] entries = [];
    size_t count;
    size_t min; // Minimum index with data.
    size_t max; // Maximum idex with data.

    // An entry.
    static struct TEntry {
        TKey key;
        TValue value;

        // dtor
        ~this() @nogc {
            static if (is(TKey == U[], U))
                nu_freea(key);
            else
                nogc_delete(key);
        }

        // postblit
        this(this) @nogc {
            static if (is(TKey == U[], U))
                this.key = key.nu_dup();
            else 
                this.key = key;
        }

        // Handles getting whether the entry is set.
        pragma(inline, true)
        bool isSet() @nogc nothrow pure {
            static if (is(typeof(() => TKey.init is null))) {
                return key !is null;
            } else {
                return key != TKey.init;
            }
        }
    }

    // Finds an entry from a key.
    TEntry* findEntry(TKey key) {
        this.growIfNeeded();

        size_t hash = hashfn(key);
        size_t index = hash % this.entries.length;
        while(true) {
            TEntry* entry = &this.entries[index];
            if (entry.key == key || !entry.isSet) {
                return entry;
            }

            index = (index+1) % this.entries.length;
        }
    }

    // Finds an entry from a key.
    TEntry* findEntry(TKey key, ref size_t index) {
        this.growIfNeeded();

        size_t hash = hashfn(key);
        index = hash % this.entries.length;
        while(true) {
            TEntry* entry = &this.entries[index];
            if (entry.key == key || !entry.isSet) {
                return entry;
            }

            index = (index+1) % this.entries.length;
        }
    }

    // Grows the storage of the hashtable if needed.
    void growIfNeeded() {
        
        // Handle initial bounds.
        if (entries.length == 0) {
            this.min = HASH_TABLE_GROW_INCREMENTS;
            this.max = 0;
        }

        // NOTE:    Resize entries and zero fill them, nu_resize
        //          does not initialize memory on its own as an optimisation.
        //          As such we really need to do this here to not get corrupted
        //          entries.
        size_t len = entries.length;
        if (this.count+1 > len*HASH_TABLE_MAX_LOAD) {
            this.entries = entries.nu_resize(nu_alignup(len+1, HASH_TABLE_GROW_INCREMENTS));
            nogc_zeroinit(entries[len..$]);
        }
    }

    // Finds the next entry in the given direction.
    ptrdiff_t findNext(size_t from, int step) {
        if (this.count == 0)
            return -1;

        size_t index = (from+step) % entries.length;
        while(true) {
            if (entries[index].isSet)
                return index;

            index = (index+step) % entries.length;
        }
    }

public:

    /**
        Length of the hash table.
    */
    @property size_t length() => count;

    /**
        Capacity of the hashtable.
    */
    @property size_t capacity() => entries.length;

    /**
        Clears the map, deleting all of the elements
        within.
    */
    void clear() @trusted {
        nu_freea(entries);
        this.count = 0;
    }

    /**
        Gets whether the hash table contains a given key.

        Params:
            key = The key to look up.

        Returns:
            $(D true) if the given key was found,
            $(D false) otherwise.
    */
    bool contains(TKey key) {
        return this.findEntry(key).isSet;
    }

    /**
        Removes the given key from the table.

        Params:
            key = The key to remove.
    */
    void remove(TKey key) {
        size_t idx;
        auto entry = this.findEntry(key, idx);
        if (entry.isSet) {
            this.count--;

            // Destroy key and value, then re-initialize entry.
            nogc_delete(*entry);
            nogc_zeroinit(*entry);

            // If we removed a min/max index, recalculate either.
            if (idx == min) {
                this.min = this.findNext(idx, 1);
            } else if (idx == max) {
                this.max = this.findNext(idx, -1);
            }
        }
    }

    /**
        Makes a clone of this hash table.
    */
    typeof(this) clone() {
        return typeof(this)(
            entries: entries.nu_dup(),
            count: count,
            min: min,
            max: max
        );
    }

    /**
        Indexes the hash table.

        Params:
            key = The key to index.

        Returns:
            The value for the given key if found,
            $(D TValue.init) otherwise.
    */
    TValue opIndex(TKey key) {
        auto entry = this.findEntry(key);
        if (entry.isSet)
            return entry.value;

        return TValue.init;
    }

    /**
        Assigns a value in the hash table.

        Params:
            value = The value to assign
            key =   The key to assign.
    */
    void opIndexAssign(TValue value, TKey key) {
        size_t idx;
        auto entry = this.findEntry(key, idx);
        if (!entry.isSet) {
            this.count++;
        }

        // New key.
        static if (is(typeof(() => TKey.init.nu_dup())))
            entry.key = key.nu_dup();
        else
            entry.key = key;
        entry.value = value;

        // If we added a new value that was lower or higher than the max, add it.
        if (idx < min) {
            this.min = idx;
        }

        if (idx > max) {
            this.max = idx;
        }
    }

    /**
        Allows iterating over the hash table.

        Params:
            dg = The function to call on each iteration.
    */
    int opApply(scope int delegate(ref TKey, ref TValue) dg) @nogc @trusted {
        // Type-casted nogc delegate.
        alias dg_t = int delegate(ref TKey, ref TValue) @nogc @trusted;
        auto dgn = cast(dg_t)dg;

        size_t i = min;
        size_t f = 0;
        while(f < count) {

            int result = dgn(entries[i].key, entries[i].value);
            if (result)
                return result;

            i = this.findNext(i, 1);
            f++;
        }
        return 0;
    }

    /// ditto
    int opApplyReverse(scope int delegate(ref TKey, ref TValue) dg) @nogc @trusted {
        // Type-casted nogc delegate.
        alias dg_t = int delegate(ref TKey, ref TValue) @nogc @trusted;
        auto dgn = cast(dg_t)dg;

        size_t i = max;
        size_t f = 0;
        while(f < count) {
            f++;

            int result = dgn(entries[i].key, entries[i].value);
            if (result)
                return result;

            i = this.findNext(i, -1);
        }
        return 0;
    }
    /// ditto
    int opApply(scope int delegate(ref TKey) dg) @nogc @trusted {

        // Type-casted nogc delegate.
        alias dg_t = int delegate(ref TKey) @nogc @trusted;
        auto dgn = cast(dg_t)dg;

        size_t i = min;
        size_t f = 0;
        while(f < count) {
            f++;

            int result = dgn(entries[i].key);
            if (result)
                return result;

            i = this.findNext(i, 1);
        }
        return 0;
    }

    /// ditto
    int opApplyReverse(scope int delegate(TKey) dg) @nogc @trusted {
        // Type-casted nogc delegate.
        alias dg_t = int delegate(TKey) @nogc @trusted;
        auto dgn = cast(dg_t)dg;

        size_t i = max;
        size_t f = 0;
        while(f < count) {
            f++;

            int result = dgn(entries[i].key);
            if (result)
                return result;

            i = this.findNext(i, -1);
        }
        return 0;
    }

    static if (!is(TKey == TValue)) {

        /// ditto
        int opApply(scope int delegate(ref TValue) dg) @nogc @trusted {

            // Type-casted nogc delegate.
            alias dg_t = int delegate(ref TValue) @nogc @trusted;
            auto dgn = cast(dg_t)dg;

            size_t i = min;
            size_t f = 0;
            while(f < count) {
                f++;

                int result = dgn(entries[i].value);
                if (result)
                    return result;

                i = this.findNext(i, 1);
            }
            return 0;
        }

        /// ditto
        int opApplyReverse(scope int delegate(ref TValue) dg) @nogc @trusted {
            // Type-casted nogc delegate.
            alias dg_t = int delegate(ref TValue) @nogc @trusted;
            auto dgn = cast(dg_t)dg;

            size_t i = max;
            size_t f = 0;
            while(f < count) {
                f++;

                int result = dgn(entries[i].value);
                if (result)
                    return result;

                i = this.findNext(i, -1);
            }
            return 0;
        }
    }
}

/**
    Computes a FNV-1a hash from a the given input.

    Params:
        in_ = The input to hash

    Returns:
        The hashed input.
*/
I fnv1a_hash(I, T)(T in_) @trusted @nogc nothrow pure 
if (__traits(isIntegral, I) && __traits(isUnsigned, I) && I.sizeof >= 4) {
    static if (I.sizeof == 4) {
        enum uint BASIS = 0x811C9DC5;
        enum uint PRIME = 0x1000193;
    } else static if (I.sizeof == 8) {
        enum ulong BASIS = 0xCBF29CE484222325;
        enum ulong PRIME = 0x100000001B3;
    } else static assert(0, "Unsupported fnv1a configuration.");

    // Get bytes of input
    static if (!is(T == U[], U))
        ubyte[] b = (cast(ubyte*)&in_)[0..T.sizeof]; 
    else
        ubyte[] b = cast(ubyte[])(cast(void[])in_);

    I hash = BASIS;
    foreach(i; 0..b.length) {
        hash ^= b[i];
        hash *= PRIME;
    }
    return hash;
}

@("HashTable!(string, int)")
unittest {
    HashTable!(string, int) a;
    a["x"] = 1;
    a["y"] = 0;

    assert(a["x"] == 1);
    assert(a["y"] == 0);

    a.remove("y");
    assert(!a.contains("y"));
}

@("HashTable iter")
unittest {
    HashTable!(string, int) a;
    a["aaaabbbb"] = 1;
    a["ccccdddd"] = 2;
    a["eeeeffff"] = 3;
    a["gggghhhh"] = 4;

    import std.stdio : writeln;

    int acc = 0;
    foreach(key, ref value; a) {
        acc += value;
    }
    assert(acc == 10);

    acc = 0;
    foreach_reverse(key, ref value; a) {
        acc += value;
    }
    assert(acc == 10);
}