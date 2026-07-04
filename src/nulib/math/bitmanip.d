/**
    NuLib Bit Manipulation

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:
        Luna Nielsen
*/
module nulib.math.bitmanip;

/**
    Circular left-shifts the given value by the given amount of bits.

    Params:
        value = The value to shift.
        count = The amount of bits to shift it by.

    Returns:
        $(D value) circular shifted $(D count) bits to the left.
*/
pragma(inline, true)
T rotl(T)(T value, uint count) @nogc nothrow pure
if (__traits(isIntegral, T)) {
    enum mask = (T.sizeof * 8)-1;
    count &= mask;
    return (value << count) | (value >>> (-count & mask));
}

/**
    Circular right-shifts the given value by the given amount of bits.

    Params:
        value = The value to shift.
        count = The amount of bits to shift it by.

    Returns:
        $(D value) circular shifted $(D count) bits to the right.
*/
pragma(inline, true)
T rotr(T)(T value, uint count) @nogc nothrow pure
if (__traits(isIntegral, T)) {
    enum mask = (T.sizeof * 8)-1;
    count &= mask;
    return (value >>> count) | (value << (-count & mask));
}