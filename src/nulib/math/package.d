/**
    Math Functions

    Important:
        When possible compiler level intrinsics will be used, but in some cases
        this is not possible; in those cases we opt to focus on readability over performance.

        As such these math functions may not be the most performant.

    Copyright: Copyright The D Language Foundation 2000 - 2011.
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:
        $(HTTP digitalmars.com, Walter Bright), 
        Don Clugston,
        Luna Nielsen

    Macros:
        SUB = $1<sub>$2</sub>
        PI = &pi;
        SQRT = &radic;
        HALF = &frac12;
*/
module nulib.math;
public import nulib.math.intrinsics;
public import nulib.math.floating;

// Values obtained from Wolfram Alpha. 116 bits ought to be enough for anybody.
// Wolfram Alpha LLC. 2011. Wolfram|Alpha. http://www.wolframalpha.com/input/?i=e+in+base+16 (access July 6, 2011).
enum real E =          0x1.5bf0a8b1457695355fb8ac404e7a8p+1L; /** e = 2.718281... */
enum real LOG2T =      0x1.a934f0979a3715fc9257edfe9b5fbp+1L; /** $(SUB log, 2)10 = 3.321928... */
enum real LOG2E =      0x1.71547652b82fe1777d0ffda0d23a8p+0L; /** $(SUB log, 2)e = 1.442695... */
enum real LOG2 =       0x1.34413509f79fef311f12b35816f92p-2L; /** $(SUB log, 10)2 = 0.301029... */
enum real LOG10E =     0x1.bcb7b1526e50e32a6ab7555f5a67cp-2L; /** $(SUB log, 10)e = 0.434294... */
enum real LN2 =        0x1.62e42fefa39ef35793c7673007e5fp-1L; /** ln 2  = 0.693147... */
enum real LN10 =       0x1.26bb1bbb5551582dd4adac5705a61p+1L; /** ln 10 = 2.302585... */
enum real PI =         0x1.921fb54442d18469898cc51701b84p+1L; /** &pi; = 3.141592... */
enum real PI_2 =       PI/2;                                  /** $(PI) / 2 = 1.570796... */
enum real PI_4 =       PI/4;                                  /** $(PI) / 4 = 0.785398... */
enum real M_1_PI =     0x1.45f306dc9c882a53f84eafa3ea69cp-2L; /** 1 / $(PI) = 0.318309... */
enum real M_2_PI =     2*M_1_PI;                              /** 2 / $(PI) = 0.636619... */
enum real M_2_SQRTPI = 0x1.20dd750429b6d11ae3a914fed7fd8p+0L; /** 2 / $(SQRT)$(PI) = 1.128379... */
enum real SQRT2 =      0x1.6a09e667f3bcc908b2fb1366ea958p+0L; /** $(SQRT)2 = 1.414213... */
enum real SQRT1_2 =    SQRT2/2;                               /** $(SQRT)$(HALF) = 0.707106... */

@safe pure:

/**
    Returns the smaller of the 2 given scalar values.

    Params:
        rhs = value
        lhs = value
    
    Returns:
        The smallest of the 2 given values.
*/
T min(T)(T lhs, T rhs) {
    return lhs < rhs ? lhs : rhs;
}

/**
    Returns the larger of the 2 given scalar values.

    Params:
        rhs = value
        lhs = value
    
    Returns:
        The largest of the 2 given values.
*/
T max(T)(T lhs, T rhs) {
    return lhs > rhs ? lhs : rhs;
}

/**
    Clamps scalar value into the given range.

    Params:
        value   = The value to clamp,
        min_    = The minimum value
        max_    = The maximum value.
    
    Returns:
        $(D value) clamped between $(D min_) and $(D max_),
        equivalent of $(D min(max(value, min_), max_))
*/
T clamp(T)(T value, T min_, T max_) {
    return min(max(value, min_), max_);
}

/**
    Modulates the given value, preserving sign bit.

    Params:
        value   = The value to modulate.
        delta   = The modulation delta.

    Returns:
        The modulated value.
*/
pragma(inline, true)
auto mod(T)(T value, T delta) {
    return copysign(abs(value) % abs(delta), value);
}

/**
    Linearly interpolates between $(D a) and $(D b)

    Params:
        a = The first value to interpolate
        b = The second value to interpolate
        t = The interpolation step from 0..1
    
    Returns:
        The interpolated value between $(D a) and $(D b)
*/
T lerp(T)(T a, T b, float t) {
    return a * (1 - t) + b * t;
}

/**
    Quadilaterally interpolates between $(D p0) and $(D p2),
    with $(D p1) as a control point.

    Params:
        p0 = The first value to interpolate
        p1 = The control value for the curve.
        p2 = The second value to interpolate
        t = The interpolation step from 0..1
    
    Returns:
        The interpolated value between $(D p0) and $(D p2)
*/
T quad(T)(T p0, T p1, T p2, float t) {
    float tm = 1.0 - t;
    float a = tm * tm;
    float b = 2.0 * tm * t;
    float c = t * t;

    return a * p0 + b * p1 + c * p2;
}

/**
    Interpolates between $(D p0) and $(D p3), using a cubic
    spline with $(D p1) and $(D p2) as control points.

    Params:
        p0 = The first value to interpolate
        p1 = The first control value for the curve.
        p2 = The second control value for the curve.
        p3 = The second value to interpolate
        t = The interpolation step from 0..1
    
    Returns:
        The interpolated value between $(D p0) and $(D p3)
*/
T cubic(T)(T p0, T p1, T p2, T p3, float t) {
    T a = -0.5 * p0 + 1.5 * p1 - 1.5 * p2 + 0.5 * p3;
    T b = p0 - 2.5 * p1 + 2 * p2 - 0.5 * p3;
    T c = -0.5 * p0 + 0.5 * p2;
    T d = p1;
    
    return a * (t ^^ 3) + b * (t ^^ 2) + c * t + d;
}

/**
    Gets whether the value's sign bit is set.

    Params:
        x = The value to check
    
    Returns:
        $(D true) if the value is signed (positive),
        $(D false) otherwise.
*/
bool signbit(T)(T x) @trusted @nogc nothrow pure if (__traits(isScalar, T)) {
    static if (__traits(isFloating, T)) {

        double tmp = cast(double)x;
        return 0 > (*cast(long*)&tmp);
    } else {

        return 0 > x;
    }
}

/**
    Copies the sign-bit from one value to another.

    Params:
        to =    The value to copy to
        from =  The value to copy from
    
    Returns:
        The value of $(D to) with the sign bit flipped
        to match $(D from).
*/
T copysign(T)(T to, T from) @safe @nogc nothrow pure if (__traits(isScalar, T)) {
    return signbit(to) == signbit(from) ? to : -to;
}
