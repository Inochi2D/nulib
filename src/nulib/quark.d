/**
    Quarks and Quark Pools

    A system heavily inspired by GLib's system of quarks,
    this essentially boils down a hash table mapping strings
    to a internal sequence number

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.quark;
import nulib.collections.hashtable;
import numem;

/**
    A quark.

    Quarks represent strings stored in an application-global
    string pool backed by a hash table.

    NOTE: The global quark pool is NOT thread safe.
*/
alias quark = uint;

/**
    A quark pool.
*/
struct QuarkPool {
private:
@nogc:
    HashTable!(quark, string) qmap;
    quark qseq;

public:

    /**
        Whether a quark exists for a given string.

        Params:
            value = The value to look up.

        Returns:
            $(D true) if the global quark store has the given key,
            $(D false) otherwise.
    */
    bool has(string value) {
        foreach(q, ref s; qmap)
            if (s == value)
                return true;
        return false;
    }

    /**
        Gets the quark for a given string.

        Params:
            value = the value to get the quark for.

        Returns:
            The quark for the given string.
    */
    quark quarkof(string value) {
        foreach(q, ref s; qmap) {
            if (s == value)
                return q;
        }

        quark q = qseq++;
        qmap[q] = value.nu_dup();
        return q;
    }
    
    /**
        Gets the stored string for a quark.

        Params:
            quark_ = The quark to look up.

        Returns:
            An implementation-owned string if found,
            $(D null) otherwise.
    */
    string stringof(quark quark_) { // @suppress(dscanner.confusing.builtin_property_names)
        if (auto str = quark_ in qmap)
            return *str;
        return null;
    }
}

/**
    Whether a quark exists for a given string in
    the global quark pool.

    Params:
        value = The value to look up.

    Returns:
        $(D true) if the global quark store has the given key,
        $(D false) otherwise.
*/
bool nu_hasquark(string value) @nogc {
    return _nu_gquark_pool.has(value);
}

/**
    Gets the quark for a given string from the global 
    quark pool.

    Params:
        value = the value to get the quark for.

    Returns:
        The quark for the given string.
*/
quark nu_quarkof(string value) @nogc {
    return _nu_gquark_pool.quarkof(value);
}

/**
    Gets the stored string for a quark from the global 
    quark pool.

    Params:
        quark_ = The quark to look up.

    Returns:
        An implementation-owned string if found,
        $(D null) otherwise.
*/
string nu_qstrof(quark quark_) @nogc {
    return _nu_gquark_pool.stringof(quark_);
}

//
//          IMPLEMENTATION DETAILS
//
private:

__gshared QuarkPool _nu_gquark_pool;