/**
    Associative Arrays

    This module implements BTree-backed associative arrays.
    @nogc associative array, replacement for std::map.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    Copyright: Guillaume Piolat 2015-2024.
    Copyright: Copyright (C) 2008- by Steven Schveighoffer. Other code
    Copyright: 2010- Andrei Alexandrescu. All rights reserved by the respective holders.
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   
        Steven Schveighoffer, 
        $(HTTP erdani.com, Andrei Alexandrescu), 
        Guillaume Piolat,
        Luna Nielsen
*/
module nulib.collections.map;
import nulib.collections.internal.btree;
import numem;

@nogc:

/**
    An associative container which contains key-value pairs.

    Notes:
        Weak types do not own the memory of their contents.
        It is up to you to free any indicies.
*/
alias weak_map(Key, Value) = MapImpl!(Key, Value, (a, b) => a < b, false, false);

/**
    An associative container which contains key-value pairs.
*/
alias map(Key, Value) = MapImpl!(Key, Value, (a, b) => a < b, false, true);

/**
    An associative container which contains key-value pairs.

    A multimap may contain multiple entries with the same $(D Key) value.

    Notes:
        Weak types do not own the memory of their contents.
        It is up to you to free any indicies.
*/
alias weak_multimap(Key, Value) = MapImpl!(Key, Value, (a, b) => a < b, true, false);

/**
    An associative container which contains key-value pairs.

    A multimap may contain multiple entries with the same $(D Key) value.
*/
alias multimap(Key, Value) = MapImpl!(Key, Value, (a, b) => a < b, true, true);

/**
    Tree-map, designed to replace std::map usage.
    The API should looks closely like the builtin associative arrays.
    O(log(n)) insertion, removal, and search time.
*/
struct MapImpl(K, V, alias less = KeyCompareDefault!Key, bool allowDuplicates = false, bool ownsMemory = false) {
public:
@nogc:

    /**
        Number of elements in the map.
    */
    @property size_t length() const @trusted => _tree.length;

    /**
        Whether the map is empty.
    */
    @property bool empty() const @trusted => _tree.empty;

    // Disables copy-construction
    @disable this(this);

    // Destructor.
    ~this() @trusted { }

    /**
        Inserts an element into the map if it's not already in the
        map.

        Params:
            key =   The key to set the value for.
            value = The value to set.
    
        Returns:
            $(D true) if $(D value) was inserted for $(D key), 
            $(D false) otherwise.
    */
    bool insert(K key, V value) @trusted {
        return _tree.insert(key, value);
    }

    /**
        Removes the given key from the map, if possible.

        Params:
            key = The key to remove the value(s) for.

        Returns:
            $(D true) if any value(s) for the key were removed,
            $(D false) otherwise.
    */
    bool remove(K key) @trusted {

        // Delete memory if this map owns it.
        static if (ownsMemory) {
            if (key in _tree) {
                nogc_delete(_tree[key]);
            }
        }

        return _tree.remove(key) != 0;
    }

    // Legacy alias.
    deprecated("Use clear() instead.")
    alias clearContents = clear;

    /**
        Clears the map, deleting all of the elements
        within.
    */
    void clear() @trusted {
        nogc_delete(_tree);
        // _tree reset to .init, still valid
    }
    
    /**
        Implements the $(D in) operator for the map,
        alternative to contains.

        Returns:
            A pointer to the value of the given key if found,
            $(D null) otherwise.    
    */
    inout(V)* opBinaryRight(string op)(K key) inout @trusted
    if (op == "in") {
        return key in _tree;
    }

    /**
        Gets the value for the given key in the map.

        Params:
            key = The key to look up.

        Returns:
            A reference to the value on success.
            Assertation or crash otherwise.
    */
    @trusted
    ref inout(V) opIndex(K key) inout {
        inout(V)* p = key in _tree;
        assert(p !is null);
        return *p;
    }

    /**
        Assigns a value to a key in the map.

        Params:
            value = The value to assign
            key =   The key to assign
    */
    void opIndexAssign(V value, K key) @trusted {
        V* p = key in _tree;
        if (p is null) {
            insert(key, value); // PERF: this particular call can assume no-dupe
        } else
            *p = value;
    }

    /**
        Gets whether the map contains the given key.

        Params:
            key = The key to check.

        Returns:
            $(D true) if the key was present,
            $(D false) otherwise.
    */
    bool contains(K key) const @trusted {
        return _tree.contains(key);
    }

    /**
        Allows iterating over the map.

        Params:
            dg = The function to call on each iteration.
    */
    int opApply(scope int delegate(TKey, TValue) dg) @nogc @trusted {
        auto kv = _tree.byKeyValue();
        while(!kv.empty()) {
            auto front = kv.front();
            int result = dg(front.key, front.value);
            if (result)
                return result;

            // So that we actually iterate.
            kv.popFront();
        }
        return 0;
    }

    /**
        Allows iterating over the map.

        Params:
            dg = The function to call on each iteration.
    */
    int opApply(scope int delegate(TValue) dg) @nogc @trusted {
        auto v = _tree.byValue();
        while(!v.empty()) {
            auto front = v.front();
            int result = dg(front);
            if (result)
                return result;

            // So that we actually iterate.
            v.popFront();
        }
        return 0;
    }

    /**
        Allows iterating over the map.

        Params:
            dg = The function to call on each iteration.
    */
    int opApply()(scope int delegate(TKey) dg) @nogc @trusted
    if (!is(TKey == TValue)) {
        auto v = _tree.byValue();
        while(!v.empty()) {
            auto front = v.front();
            int result = dg(front);
            if (result)
                return result;

            // So that we actually iterate.
            v.popFront();
        }
        return 0;
    }

private:

    alias InternalTree = BTree!(K, V, less, allowDuplicates, false);
    InternalTree _tree;
}

@("map: initialization")
unittest {
    // It should be possible to use most function of an uninitialized Map
    // All except functions returning a range will work.
    map!(int, string) m;

    assert(m.length == 0);
    assert(m.empty);
    assert(!m.contains(7));

    auto range = m.byKey();
    assert(range.empty);
    foreach (e; range) {
    }

    m[1] = "fun";
}

@("map: key collission")
unittest {
    void test(bool removeKeys) @nogc {
        {
            auto test = nogc_new!(map!(int, string))();
            int N = 100;
            foreach (i; 0 .. N) {
                int key = (i * 69069) % 65536;
                test.insert(key, "this is a test");
            }
            foreach (i; 0 .. N) {
                int key = (i * 69069) % 65536;
                assert(test.contains(key));
            }

            if (removeKeys) {
                foreach (i; 0 .. N) {
                    int key = (i * 69069) % 65536;
                    test.remove(key);
                }
            }
            foreach (i; 0 .. N) {
                int key = (i * 69069) % 65536;
                assert(removeKeys ^ test.contains(key)); // either keys are here or removed
            }
        }
    }

    test(true);
    test(false);
}

@("map: lookup")
unittest {
    // Associative array of ints that are
    // indexed by string keys.
    // The KeyType is string.
    map!(string, int) aa; 
    aa["hello"] = 3; // set value associated with key "hello" to 3
    int value = aa["hello"]; // lookup value from a key
    assert(value == 3);

    int* p;

    p = ("hello" in aa);
    if (p !is null) {
        *p = 4; // update value associated with key
        assert(aa["hello"] == 4);
    }

    aa.remove("hello");
}