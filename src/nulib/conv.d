/**
    nulib conversion functions.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.conv;
import numem.core.math;
import nulib.string;

// TODO:    This entire module should be rewritten into pure D.
//          Relying on the C standard library here is probably
//          not the best idea for portability.


/**
    Parses an integer of the given base.

    Params:
        source = The source string to parse.
    
    Returns:
        The integer parsed from the source string.
*/
T parseInt(T, S, int base = 10)(auto ref S source) @nogc nothrow pure
if (__traits(isIntegral, T)) {

    static if (__traits(isUnsigned, T))
        alias TT = ulong;
    else
        alias TT = long;

    TT result;
    size_t i = 0;
    size_t rlen = source.length;
    
    // Get whether signed value is negative.
    static if (!__traits(isUnsigned, T)) {
        bool isNegative = source[i] == '-';
        if (isNegative)
            i++;
    }

    static if (base == 16) {

        //
        //                  HEXADECIMAL
        //

        // Skip '#'
        if (i+2 < rlen && source[i..i+2] == "0x") {
            i += 2;
        } else if (i+1 < rlen && source[i] == '#') {
            i += 1;
        }

        // Parse
        while(i < rlen) {
            char c = source[i];

            // Ensure only 0-9 and A-F is allowed.
            if ((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
                result <<= 4;
                result += (c < 'A') ? (c & 0xF) : (c & 0x7) + 9;
                i++;
                continue;
            }
            break;
        }

    } else static if (base == 10) {

        //
        //                  DECIMAL
        //

        while(i < rlen) {
            char c = source[i++];

            if (c >= '0' && c <= '9') {
                result *= 10;
                result += c - '0';
                
                continue;
            }
            break;
        }

    } else static if (base == 8) {

        // Skip '0o'
        if (i+2 < rlen && source[i..i+2] == "0o")
            i += 2;

        //
        //                  OCTAL
        //
        size_t ix = 0;
        while(i < rlen) {

            char c = source[i++];
            if (c >= '0' && c <= '7') {

                result <<= 3;
                result += (c - '0');
                continue;
            }
            break;
        }

    } else static if (base == 2) {

        // Skip '0b'
        if (i+2 < rlen && source[i..i+2] == "0b")
            i += 2;

        //
        //                  BINARY
        //
        while(i < rlen) {
            char c = source[i++];
            if (c == '0' || c == '1') {

                result <<= 1;
                result |= c - '0';
                continue;
            }
            break;
        }

    } else static assert(0, "Cannot parse base "~base.stringof~" numbers.");

    // Set sign.
    static if (!__traits(isUnsigned, T)) {
        if (isNegative)
            result = -result;
    }
    return cast(T)result;
}

/**
    Parses an integer of the given base.

    Params:
        source =    The source string to parse.
        base =      The base to parse.
    
    Returns:
        The integer parsed from the source string if possible,
        otherwise $(D 0).
*/
T parseInt(T, S)(auto ref S source, int base = 10) @nogc nothrow pure
if (__traits(isIntegral, T)) {
    switch(base) {
        case 16:    return parseInt!(T, S, 16)(source);
        case 10:    return parseInt!(T, S, 10)(source);
        case 8:     return parseInt!(T, S, 8)(source);
        case 2:     return parseInt!(T, S, 2)(source);
        default: return T.init;
    }
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

/**
    Converts the given value to another type, if possible.

    Various methods will be attempted to perform the conversion,
    depending on the source and destination type.

    Params:
        value = The value to convert.

    Returns:
        The converted value, or $(D TTo)'s initial value on failure.
*/
Unqual!TTo to(TTo, TFrom)(T value) @nogc nothrow {
    static if (is(typeof(TFrom.opCast!TTo))) {

        // cast(TTo)value
        return value.opCast!TTo();
    } else static if (isSomeString!TTo && is(typeof(TFrom.toString))) {
        
        // value.toString()
        return value.toString();
    } else static if (__traits(isIntegral, TTo) && isSomeString!TFrom) {

        // value.parseInt!TTo()
        return parseInt!TTo(value);
    } else {
        debug static assert(0, "Can't convert "~TFrom.stringof~" to "~TTo.stringof~"!");
        return typeof(return).init;
    }
}