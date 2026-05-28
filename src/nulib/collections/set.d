/**
    Sets

    This module implements @nogc BTree-backed sets, replacement for std::set.

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
module nulib.collections.set;
import nulib.collections.internal.btree;
import numem;

@nogc:

/**
    An associative container which contains sets of objects of type $(D Key).

    Notes:
        Weak types do not own the memory of their contents.
        It is up to you to free any indicies.
*/
alias weak_set(Key) = SetImpl!(Key, (a, b) => a < b, false, false);

/**
    An associative container which contains sets of objects of type $(D Key).
*/
alias set(Key) = SetImpl!(Key, (a, b) => a < b, false, true);

/**
    An associative container which contains sets of objects of type $(D Key).

    A multiset may contain multiple entries with the same $(D Key) value.

    Notes:
        Weak types do not own the memory of their contents.
        It is up to you to free any indicies.
*/
alias weak_multiset(Key) = SetImpl!(Key, (a, b) => a < b, true, true);

/**
    An associative container which contains sets of objects of type $(D Key).

    A multiset may contain multiple entries with the same $(D Key) value.
*/
alias multiset(Key) = SetImpl!(Key, (a, b) => a < b, true, true);

/**
    Set, designed to replace std::set usage.
    O(log(n)) insertion, removal, and search time.
    `Set` is designed to operate even without initialization through `makeSet`.
*/
struct SetImpl(TKey, alias less = (a, b) => a < b, bool allowDuplicates = false, bool ownsMemory = false) {
public:
@nogc:

    /**
        Number of elements in the set.
    */
    @property size_t length() const @trusted => _tree.length;

    /**
        Whether the set is empty.
    */
    @property bool empty() const @trusted => _tree.empty;

    // Disables copy-construction
    @disable this(this);

    // Destructor.
    ~this() @trusted { }

    /**
        Inserts a key into the set if it's not already in
        the set.

        Params:
            key =   The key to set in the set.
    
        Returns:
            $(D true) if $(D key) was inserted, 
            $(D false) otherwise.
    */
    bool insert(TKey key) @trusted {
        ubyte whatever = 0;
        return _tree.insert(key, whatever);
    }

    /**
        Removes the given key from the set, if possible.

        Params:
            key = The key to remove the value(s) for.

        Returns:
            $(D true) if any value(s) for the key were removed,
            $(D false) otherwise.
    */
    bool remove(TKey key) @trusted {

        // Delete memory if this set owns it.
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
        Gets whether the set contains the given key.

        Params:
            key = The key to check.

        Returns:
            $(D true) if the key was present,
            $(D false) otherwise.
    */
    bool opBinaryRight(string op)(TKey key) inout @trusted
    if (op == "in") {
        return (key in _tree) !is null;
    }

    /**
        Gets whether the set contains the given key.

        Params:
            key = The key to check.

        Returns:
            $(D true) if the key was present,
            $(D false) otherwise.
    */
    bool opIndex(TKey key) const @trusted {
        return (key in _tree) !is null;
    }

    /**
        Gets whether the set contains the given key.

        Params:
            key = The key to check.

        Returns:
            $(D true) if the key was present,
            $(D false) otherwise.
    */
    bool contains(TKey key) const @trusted {
        return (key in _tree) !is null;
    }

    /**
        Allows iterating over the set.

        Params:
            dg = The function to call on each iteration.
    */
    int opApply(scope int delegate(ref TKey) dg) @nogc @trusted {

        // Type-casted nogc delegate.
        alias dg_t = int delegate(ref TKey) @nogc @trusted;

        auto k = _tree.byKey();
        while(!k.empty()) {
            auto front = k.front();
            int result = (cast(dg_t)dg)(front);
            if (result)
                return result;

            // So that we actually iterate.
            k.popFront();
        }
        return 0;
    }

    // default opSlice is like byKey for sets, since the value is a fake value.
    alias opSlice = byKey;

private:

    // dummy type
    alias TValue = ubyte;

    alias InternalTree = BTree!(TKey, TValue, less, allowDuplicates, false);
    InternalTree _tree;

}

@("set: instantiation")
unittest {
    // It should be possible to use most function of an uninitialized Set
    // All except functions returning a range will work.
    set!(string) set;

    assert(set.length == 0);
    assert(set.empty);
    set.clear();
    assert(!set.contains("toto"));

    // Finally create the internal state
    set.insert("titi");
    assert(set.contains("titi"));
}

@("set: insertion, deletion and testing")
unittest {
    set!(string) keywords;

    assert(keywords.insert("public"));
    assert(keywords.insert("private"));
    assert(!keywords.insert("private"));

    assert(keywords.remove("public"));
    assert(!keywords.remove("non-existent"));

    assert(keywords.contains("private"));
    assert(!keywords.contains("public"));
}
