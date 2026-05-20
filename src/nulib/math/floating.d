/**
    Nulib Floating Point Math

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:
        Luna Nielsen
*/
module nulib.math.floating;
import nulib.math.intrinsics;

@safe @nogc nothrow pure:

/**
    Determines whether the given value is NaN (Not a Number)

    Params:
        x   = The value to check
    
    Returns:
        $(D true) if $(D x) is NaN,
        $(D false) otherwise.
*/
bool isNaN(T)(T x) @safe @nogc nothrow pure if (__traits(isFloating, T)) {
    return x != x;
}

@("isNaN")
unittest {
    assert(isNaN(float.nan));
    assert(isNaN(double.nan));
    assert(isNaN(real.nan));
    assert(!isNaN(0.0));
    assert(!isNaN(double.infinity));
}

/**
    Determines whether the given value is a finite number.

    Params:
        x   = The value to check
    
    Returns:
        $(D true) if $(D x) is a finite, valid number,
        $(D false) otherwise.
*/
bool isFinite(T)(T x) @safe @nogc nothrow pure if (__traits(isFloating, T)) {
    return x == x && x != T.infinity && x != -T.infinity;
}

@("isFinite")
unittest {
    assert(isFinite(1.0));
    assert(!isFinite(double.nan));
    assert(!isFinite(real.infinity));
}

/**
    Determines whether the given value is an infinite number.

    Params:
        x   = The value to check
    
    Returns:
        $(D true) if $(D x) is an infinite floating point number,
        $(D false) otherwise.
*/
bool isInfinity(T)(T x) @trusted @nogc nothrow pure if (__traits(isFloating, T)) {
    static if (is(T == float)) {
        return ((*cast(uint *)&x) & 0x7FFF_FFFF) == 0x7F80_0000;
    } else static if (is(T == double)) {
        return ((*cast(ulong *)&x) & 0x7FFF_FFFF_FFFF_FFFF)
            == 0x7FF0_0000_0000_0000;
    } else return (x < -T.max) || (T.max < x);
}

@("isInfinity")
unittest {
    assert(isInfinity(float.infinity));
    assert(isInfinity(-float.infinity));
    assert(!isInfinity(double.nan));
    assert(!isInfinity(0.0));
}

/**
    Gets the fractional part of the value.

    Params:
        value = The value to get the fractional portion of

    Returns:
        The factional part of the given value.
*/
T fract(T)(T value) if(__traits(isFloating, T)) {
    return cast(T)(cast(real)value - trunc(cast(real)value));
}

@("fract")
unittest {
    assert(fract(1.5) == 0.5);
}

/**
    Computes arc-tangent of the given value.

    Params:
        x = The value
    
    Returns:
        The arc-tangent of $(D x).
*/
version(DigitalMars)
T atan(T)(T x) @safe @nogc nothrow pure {
    static if (is(T == float) && T.mant_dig == 24) {

        static immutable T[4] P = [
        -3.33329491539E-1,
            1.99777106478E-1,
        -1.38776856032E-1,
            8.05374449538E-2,
        ];
    } else static if (is(T == double)) {

        static immutable T[5] P = [
        -6.485021904942025371773E1L,
        -1.228866684490136173410E2L,
        -7.500855792314704667340E1L,
        -1.615753718733365076637E1L,
        -8.750608600031904122785E-1L,
        ];
        static immutable T[6] Q = [
            1.945506571482613964425E2L,
            4.853903996359136964868E2L,
            4.328810604912902668951E2L,
            1.650270098316988542046E2L,
            2.485846490142306297962E1L,
            1.000000000000000000000E0L,
        ];

        enum T MOREBITS = 6.123233995736765886130E-17L;
        
    } else static assert(0, T.stringof~" is not supported currently!");

    // tan(PI/8)
    enum T TAN_PI_8 = 0.414213562373095048801688724209698078569672L;

    // tan(3 * PI/8)
    enum T TAN3_PI_8 = 2.414213562373095048801688724209698078569672L;

    // Special cases.
    if (x == cast(T) 0.0)
        return x;
    if (isInfinity(x))
        return copysign(cast(T) PI_2, x);

    // Make argument positive but save the sign.
    bool sign = false;
    if (signbit(x)) {
        sign = true;
        x = -x;
    }

    static if (is(T == float) && T.mant_dig == 24) {

        // Range reduction.
        T y;
        if (x > TAN3_PI_8) {

            y = PI_2;
            x = -((cast(T) 1.0) / x);
        } else if (x > TAN_PI_8) {
            
            y = PI_4;
            x = (x - cast(T) 1.0)/(x + cast(T) 1.0);
        } else y = 0.0;

        // Rational form in x^^2.
        const T z = x * x;
        y += poly(z, P) * z * x + x;
        
    } else {
        short flag = 0;
        T y;
        if (x > TAN3_PI_8) {
            y = PI_2;
            flag = 1;
            x = -(1.0 / x);
        } else if (x <= 0.66) {
            y = 0.0;
        } else {
            y = PI_4;
            flag = 2;
            x = (x - 1.0)/(x + 1.0);
        }

        T z = x * x;
        z = z * poly(z, P) / poly(z, Q);
        z = x * z + x;

        if (flag == 2)
            z += 0.5 * MOREBITS;
        else if (flag == 1)
            z += MOREBITS;
        
        y = y + z;
    }

    return sign ? -y : y;
}

/**
    Computes arc-tangent of the given value, using signs to determine quadrant.

    Params:
        y = value
        x = value
    
    Returns:
        The arc-tangent of $(D y / x).
*/
version(DigitalMars)
T atan2(T)(T y, T x) @safe pure nothrow @nogc {

    // Special cases.
    if (isNaN(x) || isNaN(y))
        return T.nan;
    
    if (y == cast(T) 0.0) {
        if (x >= 0 && !signbit(x))
            return copysign(0, y);
        else
            return copysign(cast(T) PI, y);
    } if (x == cast(T) 0.0)
        return copysign(cast(T) PI_2, y);
    
    if (isInfinity(x)) {
        if (signbit(x)) {
            if (isInfinity(y))
                return copysign(3 * cast(T) PI_4, y);
            else
                return copysign(cast(T) PI, y);
        } else {
            if (isInfinity(y))
                return copysign(cast(T) PI_4, y);
            else
                return copysign(cast(T) 0.0, y);
        }
    }

    if (isInfinity(y))
        return copysign(cast(T) PI_2, y);

    // Call atan and determine the quadrant.
    T z = atan(y / x);

    if (signbit(x)) {
        if (signbit(y))
            z = z - cast(T) PI;
        else
            z = z + cast(T) PI;
    }

    if (z == cast(T) 0.0)
        return copysign(z, y);

    return z;
}

private:
T poly(T)(T x, T[] y) @safe @nogc nothrow pure {
    ptrdiff_t i = y.length - 1;
    T r = y[i];
    while (--i >= 0) {
        r *= x;
        r += y[i];
    }
    return r;
}
