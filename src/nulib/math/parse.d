/**
    Number parsing

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.math.parse;
import numem.core.math;

/**
    Parses an integer of the given base.

    Params:
        source = The source string to parse.
    
    Returns:
        The integer parsed from the source string.
*/
T parseInt(T, S, int base = 10)(auto ref S source) @nogc nothrow
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
            b = (source[i] & 0xF) + (source[i] >> 6) | ((source[i] >> 3) & 0x8);
            result = (result << 4) | b;
            i++;
        }

    } else static if (base == 10) {

        //
        //                  DECIMAL
        //
        foreach(i; 0..nu_min(maxRead, source.length)) {

            result *= 10;
            result += source[i] - '0';
        }

    } else static if (base == 8) {

        //
        //                  OCTAL
        //

        // TODO

    } else static if (base == 2) {

        //
        //                  BINARY
        //
        
        // TODO

    } else static assert(0, "Cannot parse base "~base.stringof~" numbers.");

    // Set sign.
    static if (!__traits(isUnsigned, T)) {
        if (isNegative)
            result = -result;
    }
    return cast(T)result;
}