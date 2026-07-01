/**
    Common data types and functions used during parsing operations.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
*/
module nulib.conv.algorithms.common;
import nulib.conv.integral;
import nulib.text.ascii;
import nulib.string;
import numem.core.traits;
import numem.core.math;




//
//              TYPES
//

/**
    Gets whether the characters in the given buffer should be parsed
    as a floating pointer number or integer.

    Params:
        buffer =    The buffer to check
        sep =       The decimal point seperator

    Returns:
        $(D true) if the buffer's upcoming characters can be parsed as
        an integer, $(D false) otherwise.
*/
bool isIntegerString(string buffer, char sep='.') @nogc nothrow pure {
    import nulib.text.ascii : isDigit, toLower;
    size_t i = 0;
    
    // Skip negative sign
    if (buffer[i] == '-' || buffer[i] == '+')
        i++;

    // Not a number.
    if (!isDigit(buffer[i]))
        return false;

    while(i < buffer.length) {
        char c = buffer[i++];
    
        if (c == sep)
            return false;

        if (!isDigit(c))
            return true;
    }
    return true;
}




//
//              INTEGERS
//

/**
    Parses an integer of the given base.

    Params:
        source =    The source string to parse.
        dest =      The destination number to store the value in.
        digits =    Amount of digits parsed.
    
    Returns:
        The amount of elements read from the string,
        $(D -1) if the integer could not be parsed.
*/
pragma(inline, true)
ptrdiff_t parseIntString(T, S, int base = 10)(auto ref S source, ref T dest, ref T digits) @nogc nothrow pure
if (isSomeString!S && __traits(isIntegral, T)) {
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

        // Skip prefix.
        if (source[i..$].startsWith("0x")) {
            i += 2;
        } else if (source[i..$].startsWith('#')) {
            i += 1;
        }

        // Skip leading zeroes.
        while(i < rlen && source[i] == '0') i++;

        // Parse
        while(i < rlen) {
            char c = source[i];

            // Skip underscores.
            if (c == '_')
                continue;

            // Ensure only 0-9 and A-F is allowed.
            if ((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
                result <<= 4;
                result += (c < 'A') ? (c & 0xF) : (c & 0x7) + 9;
                i++;
                digits++;
                continue;
            }
            break;
        }

    } else static if (base == 10) {

        // Skip leading zeroes.
        while(i < rlen && source[i] == '0') i++;

        //
        //                  DECIMAL
        //
        while(i < rlen) {
            char c = source[i++];

            // Skip underscores.
            if (c == '_')
                continue;

            if (c >= '0' && c <= '9') {
                result *= 10;
                result += c - '0';
                digits++;
                
                continue;
            }
            break;
        }

    } else static if (base == 8) {

        // Skip prefix.
        if (i+2 < rlen && source[i..i+2] == "0o")
            i += 2;

        // Skip leading zeroes.
        while(i < rlen && source[i] == '0') i++;

        //
        //                  OCTAL
        //
        size_t ix = 0;
        while(i < rlen) {
            char c = source[i++];

            // Skip underscores.
            if (c == '_')
                continue;

            if (c >= '0' && c <= '7') {

                result <<= 3;
                result += (c - '0');
                digits++;
                continue;
            }
            break;
        }

    } else static if (base == 2) {

        // Skip prefix.
        if (i+2 < rlen && source[i..i+2] == "0b")
            i += 2;

        // Skip leading zeroes.
        while(i < rlen && source[i] == '0') i++;

        //
        //                  BINARY
        //
        while(i < rlen) {
            char c = source[i++];

            // Skip underscores.
            if (c == '_')
                continue;

            if (c == '0' || c == '1') {

                result <<= 1;
                result |= c - '0';
                digits++;
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
    dest = cast(T)result;
    return i;
}

/**
    Parses an integer of the given base.

    Params:
        source =    The source string to parse.
        dest =      The destination number to store the value in.
        digits =    Amount of digits parsed.
        base =      The base of the integer to parse.
    
    Returns:
        The amount of elements read from the string,
        $(D -1) if the integer could not be parsed.
*/
pragma(inline, true)
ptrdiff_t parseIntString(T, S)(auto ref S source, ref T dest, ref T digits, int base = 0) @nogc nothrow pure
if (isSomeString!S && __traits(isIntegral, T)) {
    switch(base) {
        case 16:    return parseIntString!(T, S, 16)(source, dest, digits);
        case 10:    return parseIntString!(T, S, 10)(source, dest, digits);
        case 8:     return parseIntString!(T, S, 8)(source, dest, digits);
        case 2:     return parseIntString!(T, S, 2)(source, dest, digits);
        case 0:     return parseIntString!(T, S)(source, dest, digits, determineIntBase(source));
        default: return -1;
    }
}

/**
    Determines the base that the given integer is in.

    Params:
        source = The source string to check

    Returns:
        The detected base of the integer,
        $(D -1) if an invalid integer was passed.
*/
int determineIntBase(S)(auto ref S source) @nogc nothrow pure
if (isSomeString!S) {
    // Easy checks.
    if (source.startsWith("0x")) return 16;
    else if (source.startsWith("0o")) return 8;
    else if (source.startsWith("0b")) return 2;
    else if (source[0].toLower() > 'f') return -1;

    // Check if we can find any hex characters.
    foreach(i; 0..nu_min(source.length, 8)) {
        char c = source[i].toLower();
        if (c >= 'a' && c >= 'f')
            return 16;
    }    

    // At that point we just assume decimal.
    return 10;
}




//
//              FLOATS
//

/**
    Struct representing the parsed elements
    of a floating point number.
*/
struct ParsedFloat {

    /**
        How many bytes were read from the string.
    */
    size_t bytesRead;

    /**
        The mantissa of the float.
    */
    ulong mantissa;

    /**
        The exponent of the float.
    */
    int exponent;

    /**
        Whether the float is negative.
    */
    bool isNegative;

    /**
        Whether the float was truncated.
    */
    bool isTruncated;

    /**
        Whether parsing the float succeeded.
    */
    bool ok;
}

/**
    Parses the given string as a float.

    Params:
        str = The string to parse.
        sep = The fractional point seperator.

    Returns:
        The parsed float.
*/
ParsedFloat parseFloatString(T)(T str, const(char) sep='.') @trusted @nogc nothrow pure {
    ParsedFloat result;
    size_t i = 0;       // Parse offset

    // No data.
    if (str.length == 0)
        return result;

    // Handle +/-
    result.isNegative = str[i] == '-';
    if (str[i] == '-' || str[i] == '+') {
        i++;
    }

    // Parse the string.
    int nd = 0;
    int ndmant = 0;
    int dp = 0;
    bool sawsep = false;
    bool sawdigits = false;
    loop: while(i < str.length) {
        char c = str[i++].toLower();
        switch(c) {

            // Skip underscores.
            case '_': 
                continue loop;

            // Parse seperator.
            case sep:
                if (sawsep)
                    return result;

                sawsep = true;
                dp = nd;
                continue loop;

            // Parse digits.
            case '0': .. case'9':
                sawdigits = true;

                // Skip leading zeroes.
                if (c == '0' && nd == 0) {
                    dp--;
                    continue;
                }
                nd++;
                if (ndmant < 19) {
                    result.mantissa *= 10;
                    result.mantissa += cast(ulong)(c - '0');
                    ndmant++;
                } else if (c != '0') {
                    result.isTruncated = true;
                }
                continue loop;

            default:
                break loop;
        }
    }

    // Backtrack one, so that we can parse exponents.
    i--;

    // No digits found, not a float?
    if (!sawdigits) {
        return result;
    }
    
    // Just an integer.
    if (!sawsep) {
        dp = nd;
    }

    // Parse exponent.
    if (i < str.length && str[i].toLower() == 'e') {
        i++;

        // No exponent?
        if (i >= str.length)
            return result;

        // Parse sign
        int expSign = (str[i] == '-') ? -1 : 1;
        if (str[i] == '-' || str[i] == '+')
            i++;

        // Not a digit?
        if (i >= str.length || !str[i].isDigit)
            return result;

        int exp = 0;
        while(i < str.length) {
            char c = str[i++].toLower();
            if (c == '_') {

                // Skip underscores.
                continue;
            } else if (exp < 10_000 && c.isDigit) {
                exp = (exp*10) + cast(int)(c - '0');
                continue;
            }

            // Not a character.
            break;
        }
        dp += exp * cast(int)expSign;
    }

    if (result.mantissa != 0)
        result.exponent = dp - ndmant;

    result.bytesRead = i;
    result.ok = true;
    return result;
}


//
//              Adjusted Mantissa
//

/**
    Represents a mantissa adjusted by a binary power.
*/
struct AdjustedMantissa {
@nogc nothrow pure:
public:
    /*
        The mantissa.
    **/
    ulong mantissa;

    /**
        The adjustment power.
    */
    int pow2;
}