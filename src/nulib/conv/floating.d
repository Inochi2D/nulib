/**
    NuLib floating-point conversion.
    
    Implements the Eisel-Lemire algorithm described in the paper
    "Number Parsing at Gigabytes per Second", Software: Practice
    and Experience 51 (8), 2021 and as described in 
    "The Eisel-Lemire ParseNumberF64 Algorithm" by Nigel Tao.

    A fallback parser is provided via Simple Decimal Conversion
    as described in "ParseNumberF64 by Simple Decimal Conversion"
    by Nigel Tao.
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
        Ken Thompson (Fast left-shift)
        Michael Eisel (Original work)
        Daniel Lemire (Original work)
        Nigel Tao (Algorithm reference)

    See_Also:
        $(LINK2 https://github.com/golang/go/blob/go1.15.3/src/strconv/decimal.go#L163, Fast left-shift)
        $(LINK2 https://nigeltao.github.io/blog/2020/parse-number-f64-simple.html, ParseNumberF64 by Simple Decimal Conversion)
        $(LINK2 https://nigeltao.github.io/blog/2020/eisel-lemire.html, The Eisel-Lemire ParseNumberF64 Algorithm)
        $(LINK2 https://arxiv.org/pdf/2101.11408, Number Parsing at a Gigabyte per Second)
*/
module nulib.conv.floating;
import nulib.conv.algorithms.common;
import nulib.conv.algorithms.eisel_lemire;
import nulib.conv.algorithms.sdc;
import nulib.string;
import nulib.math;
import numem.core.math;


/**
    Parses a floating point number from a string.

    Params:
        source =    The source string.
        sep =       The decimal seperator.

    Returns:
        The parsed float or NaN on failure.
*/
FT parseFloat(FT, S)(S source, char sep='.') @nogc nothrow
if (__traits(isFloating, FT)) {
    if (source.length == 0)
        return FT.nan;

    // Try parse special cases ((+/-)nan and (+/-)infinity)
    FT result;
    if (parseSpecial!FT(source, result)) {
        return result;
    }

    // Try parsing float.
    ParsedFloat pf = parseFloatString(source, sep);
    if (!pf.ok) {
        return result;
    }

    // Try eisel Lemire method.
    if (eiselLemire!FT(pf.mantissa, pf.exponent, pf.isNegative, result)) {
        return result;
    }

    // Fallback to SDC.
    bool overflow;
    Decimal d = parseDecimal(source, sep);
    result = d.toFloat!FT(overflow);
    
    // That failed too?!? Return NaN.
    if (overflow)
        return FT.nan;

    return result;
}

@("parseFloat: float fuzz test")
unittest {
    import std.random : uniform01;
    import std.conv : text;
    import std.math : fabs;

    foreach(i; 0..10_000) {
        float ft = uniform01!float();
        float r = parseFloat!float(ft.text);
        assert(fabs(r - ft) < 0.00001, r.text~" != "~ft.text);
    }
}

@("parseFloat: double fuzz test")
unittest {
    import std.random : uniform01;
    import std.conv : text;
    import std.math : fabs;

    foreach(i; 0..10_000) {
        double ft = uniform01!double();
        double r = parseFloat!double(ft.text);
        assert(fabs(r - ft) < 0.00001, r.text~" != "~ft.text);
    }
}

/**
    Gets the string representation of a given floating point
    number.

    Params:
        source =    The source number.

    Returns:
        A string representing the number.
*/
nstring toString(S)(S source) @nogc nothrow
if (__traits(isFloating, S)) {
    bool isNegative = signbit(source);

    // Handle special cases.
    if (isNaN(source)) {
        return nstring("+nan");
    } else if (isInfinity(source)) {
        return isNegative ? nstring("+inf") : nstring("-inf");
    }
    
    assert(0, "TODO");
    return nstring.init;
}




//
//          IMPLEMENTATION DETAILS
//
private:

// Helper that does fast case insensitive ascii comparison
pragma(inline, true)
bool __strncasecmp(S)(inout(S) lhs, inout(S) rhs) @nogc nothrow pure {
    ubyte rdiff;
    foreach(i; 0..nu_min(lhs.length, rhs.length)) {
        rdiff |= (lhs[i] ^ rhs[i]);
    }
    return rdiff == 0 || rdiff == 32;
}

// Parses special cases such as positive and negative infinity.
bool parseSpecial(FT, S)(auto ref inout(S) str, ref FT result) @nogc nothrow pure {
    if (str.length == 0)
        return false;

    size_t i = 0;
    bool neg = str[i] == '-';
    if (str[i] == '-' || str[i] == '+') {
        i++;
    }

    // No more characters.
    if (i >= str.length)
        return false;

    if (__strncasecmp(str[i..$], "inf") || __strncasecmp(str[i..$], "infinity")) {
        result = neg ? -FT.infinity : FT.infinity;
        return true;
    }

    if (__strncasecmp(str[i..$], "nan")) {
        result = neg ? -FT.nan : FT.nan;
        return true;
    }

    return false;
}