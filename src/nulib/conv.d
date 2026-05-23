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

    // Maximum characters to read.
    enum maxRead = T.sizeof*2;

    static if (__traits(isUnsigned, T))
        alias TT = ulong;
    else
        alias TT = long;

    TT result;
    size_t i = 0;
    size_t rlen = nu_min(maxRead, source.length);
    
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

        // Skip '0x'
        if (i+2 < rlen && source[i] == '0' && source[i] == 'x')
            i += 2;

        // Parse
        ubyte b;
        while(i < rlen) {
            char c = source[i];

            b = (c & 0xF) + (c >> 6) | ((c >> 3) & 0x8);
            result = (result << 4) | b;
            i++;
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
        if (i+2 < rlen && source[i] == '0' && source[i] == 'o')
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

        // Skip '0x'
        if (i+2 < rlen && source[i] == '0' && source[i] == 'b')
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
    return parseInt(str, base);
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