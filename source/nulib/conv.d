/**
    nulib conversion functions.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.conv;
import nulib.c.stdlib;
import nulib.c.stdio;
import nulib.string;
import nulib.math;
import nulib.text.ascii;
import numem.core.traits;
import numem.core.hooks;
import numem.core.exception;

// TODO:    This entire module should be rewritten into pure D.
//          Relying on the C standard library here is probably
//          not the best idea for portability.

/**
    Converts the given string slice to an integral value.

    Params:
        str = The string to convert.
        base = The base to read the string as.
    
    Returns:
        The integral value on success, or $(D 0) on failure.
*/
T to_integral(T)(inout(char)[] str, int base = 10) @nogc nothrow if (__traits(isIntegral, T)) {
    if (str.length == 0)
        return T.init;
    
    auto tmp = _tmpbuffer!8(str);
    ulong out_;
    switch(base) {
        case 8:
            cast(void)sscanf(tmp.ptr, "%llo", &out_);
            return cast(T)out_;

        case 10:
            static if (T.sizeof <= 4)
                return cast(T)atoi(tmp.ptr);
            else
                return cast(T)atoll(tmp.ptr);

        case 16:
            cast(void)sscanf(tmp.ptr, "%8llx", &out_);
            return cast(T)out_;

        default:
            return T.init;
    }
}

/// ditto
alias toInt = to_integral;

/**
    Converts the given string slice to an floating point value.

    Params:
        str = The string to convert.
    
    Returns:
        The floating point value on success, or $(D 0.0) on failure.
*/
T to_floating(T)(inout(char)[] str) @nogc nothrow if (__traits(isFloating, T)) {
    auto tmp = _tmpbuffer!32(str);
    return cast(T)atof(tmp.ptr);
}

/// ditto
alias toFloat = to_floating;

/**
    Converts the given value to a string.

    Params:
        value = The input value.

    Returns:
        A string parsed from $(D input).
*/
nstring to_string(T)(T value) @nogc {
    static if (isStringable!T) {
        
        return nstring(assumeNoThrowNoGC((T value) { return input.toString(); }, value));
    } static if (isPointer!T) {
        
        return to_string_impl("%p", value);
    } else static if (__traits(isIntegral, T)) {
        
        static if (__traits(isUnsigned, T)) {
            return to_string_impl("%llu", cast(ulong)value);
        } else {
            return to_string_impl("%lld", cast(long)value);
        }
    } else static if (__traits(isFloating, T)) {

        return to_string_impl("%f", value);
    } else {

        return nstring(T.stringof);
    }
}

/// ditto
alias text = to_string;

/**
    Converts the given value to a hexidecimal string.

    Params:
        value = The input value.

    Returns:
        A string parsed from $(D input).
*/
nstring to_hex_string(T)(T value, bool lowercase = true) if (__traits(isIntegral, T)) {
    nstring tmp = to_string_impl("%.*x", T.sizeof*2, value);

    if (lowercase) {
        foreach(ref char c; cast(char[])tmp[]) {
            c = toLower(c);
        }
    }
    return tmp;
}

/// ditto
alias toHexString = to_hex_string;

/**
    Converts the given value to a octal string.

    Params:
        value = The input value.

    Returns:
        A string parsed from $(D input).
*/
nstring to_oct_string(T)(T value) if (__traits(isIntegral, T)) {
    return to_string_impl("%.*o", T.sizeof*2, value); 
}

/// ditto
alias toOctalString = to_oct_string;



/**
    Parses a hexidecimal number from the source.

    Params:
        source = The source string
    
    Returns:
        The number parsed from the source string.
*/
T parseHex(T, S)(auto ref S source) @nogc nothrow
if (__traits(isIntegral, T)) {
    enum maxRead = T.sizeof*2;
    ulong result;
    ubyte b;

    foreach(i; 0..min(maxRead, source.length)) {
        b = (source[i] & 0xF) + (source[i] >> 6) | ((source[i] >> 3) & 0x8);
        result = (result << 4) | b;
    }
    return cast(T)result;
}


//
//          IMPLEMENTATION DETAILS
//

private:

// Tables that contain the various printf modifiers
// used in string conversion.
__gshared const(char)*[4][2] _NU_IFMT_TABLE = [
    ["%hhu", "%hu", "%u", "%llu"], 
    ["%hhi", "%hi", "%i", "%lli"]
];

__gshared const(char)*[4][2] _NU_IFMT_TABLE_HEX = [
    ["%hhx", "%hx", "%x", "%llx"], 
    ["%hhX", "%hX", "%X", "%llX"]
];

__gshared const(char)*[4] _NU_IFMT_TABLE_OCT = 
    ["%hho", "%ho", "%o", "%llo"];

nstring to_string_impl(T...)(const(char)* fmtstring, T input) @nogc {
    int reqlen = snprintf(null, 0, fmtstring, input);

    if (reqlen) {
        size_t rlen = reqlen+1;

        char* tmp = cast(char*)nu_malloc(rlen);
        cast(void)snprintf(tmp, rlen, fmtstring, input);
        
        nstring out_ = nstring(tmp[0..rlen]);
        nu_free(cast(void*)tmp);
        return out_;
    }

    return nstring.init;
}

/**
    Creates a temporary buffer of the specified length.
*/
char[len] _tmpbuffer(uint len)(inout(char)[] str) return {
    size_t tbOffset = min(8, str.length);
    char[len] tmp = 0;
    tmp[0..tbOffset] = str[0..tbOffset];
    return tmp;
}
