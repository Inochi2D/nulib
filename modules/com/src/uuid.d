/**
    NuLib COM UUID Utilities

    Copyright: Copyright © 2023-2025, Kitsunebi Games
    Copyright: Copyright © 2023-2025, Inochi2D Project
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.com.uuid;
import numem.core.traits : getUDAs, hasUDA;
import nuuuid = nulib.uuid;

/**
    UUID
*/
alias UUID = nuuuid.UUID;
alias uuid_t = UUID; /// ditto

/**
    A Compile-Time Globally Unique Identifier.
*/
enum Guid(string guid) = nuuuid.CTUUID!(guid);

/**
    A Globally Unique Identifier.
*/
enum Guid(uint time_low, ushort time_mid, ushort time_hi_and_version, ubyte clk0, ubyte clk1, ubyte d0, ubyte d1, ubyte d2, ubyte d3, ubyte d4, ubyte d5) = 
    nuuuid.UUID(time_low, time_mid, time_hi_and_version, clk0, clk1, d0, d1, d2, d3, d4, d5);

/**
    Globally unique identifier.
*/
alias GUID = UUID;
alias LPGUID = GUID*; /// ditto
alias LPCGUID = const(GUID)*; /// ditto
alias REFGUID = const(GUID)*; /// ditto

/**
    A null GUID
*/
enum GUID GUID_NULL = UUID(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
alias IID_NULL = GUID_NULL; /// ditto
alias CLSID_NULL = GUID_NULL; /// ditto

/**
    Interface ID
*/
alias IID = UUID;
alias LPIID = IID*; /// ditto
alias LPCIID = const(IID)*; /// ditto
alias REFIID = const(IID)*; /// ditto

/**
    Class ID
*/
alias CLSID = UUID;
alias LPCLSID = CLSID*; /// ditto
alias LPCCLSID = const(CLSID)*; /// ditto
alias REFCLSID = const(CLSID)*; /// ditto

/**
    Format ID
*/
alias FMTID = const(UUID);
alias LPFMTID = FMTID*; /// ditto
alias LPCFMTID = const(FMTID)*; /// ditto
alias REFFMTID = const(FMTID)*; /// ditto

/**
    Gets the $(D Guid) for the given type if possible.

    You can check if a type has a Guid with a $(D is(__uuidof!T)) expression.
*/
template __uuidof(T, A...) {
    import nulib.com.uuid : Guid;

    static if (A.length == 0) {
        alias attrs = __traits(getAttributes, T);

        static if (attrs.length > 0)
            enum __uuidof = __uuidof!(T, attrs);
        else
            static assert(0, T.stringof~" lacks a GUID!");
    } else static if (A.length == 1) {
        static assert (is(typeof(A[0]) == UUID), T.stringof~" lacks a GUID!");
        enum __uuidof = A[0];
    } else static if (is(typeof(A[0]) == UUID)) {
        enum __uuidof = A[0];
    } else {
        enum __uuidof = __uuidof!(T, A[1 .. $]);
    }
}

