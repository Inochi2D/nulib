/**
    NuLib Integral Conversion

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.conv.integral;
import numem.core.math;
import numem.core.traits;
import nulib.string;

import nulib.conv.algorithms.common;

/**
    Parses an integer of the given base.

    Params:
        source =    The source string to parse.
        base =      The base to parse.
    
    Returns:
        The integer parsed from the source string if possible,
        otherwise $(D 0).
*/
T parseInt(T, S)(auto ref S source, int base = 0) @nogc nothrow pure
if (__traits(isIntegral, T)) {
    T result = T.init;  // Result
    T digits = void;    // Throwaway
    switch(base) {
        default: break;

        case 16:
            cast(void)parseIntString!(T, S, 16)(source, result, digits);
            break;

        case 10:
            cast(void)parseIntString!(T, S, 10)(source, result, digits);
            break;

        case 8:
            cast(void)parseIntString!(T, S, 8)(source, result, digits);
            break;

        case 2:
            cast(void)parseIntString!(T, S, 2)(source, result, digits);
            break;

        case 0:
            return parseInt!(T, S)(source, determineIntBase(source));
    }
    return result;
}

@("parseInt")
unittest {

    // Without prefix.
    assert(parseInt!int("FF", 16) == 0xFF);
    assert(parseInt!int("24", 10) == 24);
    assert(parseInt!int("224", 8) == 148);
    assert(parseInt!int("11011", 2) == 0b11011);

    // With prefix.
    assert(parseInt!int("0xFF", 16) == 0xFF);
    assert(parseInt!uint("0xAABBCCDD", 16) == 0xAABBCCDD);
    assert(parseInt!uint("#AABBCCDD", 16) == 0xAABBCCDD);
    assert(parseInt!int("0o224", 8) == 148);
    assert(parseInt!int("0b11011", 2) == 0b11011);

    // Auto detection.
    assert(parseInt!int("1234") == 1234);
    assert(parseInt!int("123F") == 0x123F);
    assert(parseInt!int("0x1234") == 0x1234);
    assert(parseInt!int("0b1101") == 0b1101);
    assert(parseInt!int("0o224") == 148);
}

/**
    Writes the given integer to the given destination string.

    Params:
        source =        The souce integer.
        destination =   The destination string slice to write to.
        base =          The base of the value.
        pad =           Character to use for padding, null for no padding.

    Returns:
        The amount of elements written, or
        $(D -1) if the string could not be parsed.
*/
ptrdiff_t swritei(S, D, bool upper=true)(S source, inout(D)[] destination, int base = 10, D pad = '\0') @nogc nothrow
if (__traits(isIntegral, S)) {
    import nulib.string : digits;

    static if (upper)
        __gshared const D[] _HEX_TABLE = "0123456789ABCDEFGHIJKLMNOPQRSTUV";
    else
        __gshared const D[] _HEX_TABLE = "0123456789abcdefghijklmnopqrstuv";

    ptrdiff_t wlen = nu_min(digits(source, base), destination.length);
    D[] dst = cast(D[])destination;
    S num = source;

    ptrdiff_t   j = 0;      // write offset
    ptrdiff_t   w = 0;      // written count
    ptrdiff_t   i = 0;      // index

    // Handle negative numbers.
    static if (!__traits(isUnsigned, S)) {
        if (num < 0) {

            // Make positive.
            num = -num;

            // Skip one character forward and add minus symbol
            dst[i] = '-';
            j++;
        }
    }

    // Add padding
    if (pad != '\0') {
        wlen = nu_min(digits(S.max, base)+j, destination.length);
        dst[j..wlen] = pad;
    }

    // Move to back.
    i = wlen;
    if (base > 1 && base <= _HEX_TABLE.length) {

        // Write the data.
        do {

            dst[--i] = _HEX_TABLE[num % base];
            num = cast(S)(num / base);
        } while(i > j && num > 0);
        return wlen;
    }
    return -1;
}

/**
    Writes the given integer to the given destination string.

    Params:
        source =        The souce integer.
        destination =   The destination string slice to write to.
        base =          The base of the value.
        pad =           Character to use for padding, null for no padding.
        upper =         Whether to write values in upper case

    Returns:
        The amount of elements written, or
        $(D -1) if the string could not be parsed.
*/
ptrdiff_t swritei(S, D)(S source, inout(D)[] destination, int base, D pad = '\0', bool upper = true) @nogc nothrow {
    if (upper)
        return swritei!(S, D, true)(source, destination, base, pad);
    else
        return swritei!(S, D, false)(source, destination, base, pad);
}

@("swritei")
unittest {
    static string swriteTestFunc(T)(T value, int base) {
        string buffer = new string(255);
        ptrdiff_t w = swritei(value, buffer, base);
        return buffer[0..w];
    }

    // Unsigned
    assert(swriteTestFunc(ubyte(0xFF), 16) == "FF");
    assert(swriteTestFunc(ubyte(24), 10) == "24");
    assert(swriteTestFunc(ubyte(148), 8) == "224");
    assert(swriteTestFunc(ubyte(0b11011), 2) == "11011");

    // Signed
    assert(swriteTestFunc(-0xFAFA, 16) == "-FAFA");
}

/**
    Converts the given string slice to an integral value.

    Params:
        str = The string to convert.
        base = The base to read the string as.
    
    Returns:
        The integral value on success, or $(D 0) on failure.
*/
T toInt(T)(inout(char)[] str, int base = 10) @nogc nothrow
if (__traits(isIntegral, T)) {
    return parseInt!T(str, base);
}