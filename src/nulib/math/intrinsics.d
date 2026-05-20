/**
    Bindings to compiler-specific intrinsics wrapped in a nicer interface.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:
        Luna Nielsen
*/
module nulib.math.intrinsics;
import nulib.math.fixed;

version (GNU) import gcc.builtins;
else version (LDC) import ldc.intrinsics;
else {
    import nmath = nulib.math.floating;
    import cmath = nulib.c.math;
}

@safe @nogc nothrow pure:

/**
    Computes the square root of the given value.

    Params:
        x = The value
    
    Returns:
        The square root of $(D x).
*/
pragma(inline, true)
T sqrt(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return x < 0 ? T.nan : llvm_sqrt(x);
    }  else version(GNU) {
        static if (is(T == float))
            return __builtin_sqrtf(x);
        else static if (is(T == double))
            return __builtin_sqrt(x);
        else static if (is(T == real))
            return __builtin_sqrtl(x);
    } else {
        return cast(T)cmath.sqrt(cast(double)x);
    }
}

@("sqrt")
unittest {
    assert(sqrt(9.0) == 3.0);
    assert(sqrt(10.0) == 3.1622776601683795);
}

/**
    Computes sine of the given value.

    Params:
        x = The value
    
    Returns:
        The sine of $(D x).
*/
pragma(inline, true)
T sin(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_sin!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_sinf(x);
        else static if (is(T == double))
            return __builtin_sin(x);
        else static if (is(T == real))
            return __builtin_sinl(x);
    } else {
        return cast(T)cmath.sin(cast(double)x);
    }
}

/**
    Computes cosine of the given value.

    Params:
        x = The value
    
    Returns:
        The cosine of $(D x).
*/
pragma(inline, true)
T cos(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_cos!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_cosf(x);
        else static if (is(T == double))
            return __builtin_cos(x);
        else static if (is(T == real))
            return __builtin_cosl(x);
    } else {
        return cast(T)cmath.cos(cast(double)x);
    }
}

/**
    Computes tangent of the given value.

    Params:
        x = The value
    
    Returns:
        The tangent of $(D x).
*/
pragma(inline, true)
T tan(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_tan!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_tanf(x);
        else static if (is(T == double))
            return __builtin_tan(x);
        else static if (is(T == real))
            return __builtin_tanl(x);
    } else {
        return cast(T)cmath.tan(cast(double)x);
    }
}

/**
    Computes arc-sine of the given value.

    Params:
        x = The value
    
    Returns:
        The arc-sine of $(D x).
*/
pragma(inline, true)
T asin(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_asin!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_asinf(x);
        else static if (is(T == double))
            return __builtin_asin(x);
        else static if (is(T == real))
            return __builtin_asinl(x);
    } else {
        return cast(T)cmath.asin(cast(double)x);
    }
}

/**
    Computes arc-cosine of the given value.

    Params:
        x = The value
    
    Returns:
        The arc-cosine of $(D x).
*/
pragma(inline, true)
T acos(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_acos!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_acosf(x);
        else static if (is(T == double))
            return __builtin_acos(x);
        else static if (is(T == real))
            return __builtin_acosl(x);
    } else {
        return cast(T)cmath.acos(cast(double)x);
    }
}

/**
    Computes arc-tangent of the given value.

    Params:
        x = The value
    
    Returns:
        The arc-tangent of $(D x).
*/
pragma(inline, true)
T atan(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_atan!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_atanf(x);
        else static if (is(T == double))
            return __builtin_atan(x);
        else static if (is(T == real))
            return __builtin_atanl(x);
    } else version(DigitalMars) {
        return nmath.atan(x); 
    } else {
        return cast(T)cmath.atan(cast(double)x);
    }
}

/**
    Computes arc-tangent of the given value, using signs to determine quadrant.

    Params:
        y = value
        x = value
    
    Returns:
        The arc-tangent of $(D y / x).
*/
pragma(inline, true)
T atan2(T)(T y, T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_atan2!T(y, x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_atan2f(y, x);
        else static if (is(T == double))
            return __builtin_atan2(y, x);
        else static if (is(T == real))
            return __builtin_atan2l(y, x);
    } else version(DigitalMars) {
        return nmath.atan2(y, x); 
    } else {
        return cast(T)cmath.atan2(cast(double)x, cast(double)y);
    }
}

/**
    Computes hyperbolic sine of the given value.

    Params:
        x = The value
    
    Returns:
        The hyperbolic sine of $(D x).
*/
pragma(inline, true)
T sinh(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_sinh!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_sinhf(x);
        else static if (is(T == double))
            return __builtin_sinh(x);
        else static if (is(T == real))
            return __builtin_sinhl(x);
    } else {
        return cast(T)cmath.sinh(cast(double)x);
    }
}

/**
    Computes hyperbolic cosine of the given value.

    Params:
        x = The value
    
    Returns:
        The hyperbolic cosine of $(D x).
*/
pragma(inline, true)
T cosh(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_cosh!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_coshf(x);
        else static if (is(T == double))
            return __builtin_cohs(x);
        else static if (is(T == real))
            return __builtin_coshl(x);
    } else {
        return cast(T)cmath.cosh(cast(double)x);
    }
}

/**
    Computes hyperbolic tangent of the given value.

    Params:
        x = The value
    
    Returns:
        The hyperbolic tangent of $(D x).
*/
pragma(inline, true)
T tanh(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_tanh!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_tanhf(x);
        else static if (is(T == double))
            return __builtin_tanh(x);
        else static if (is(T == real))
            return __builtin_tanhl(x);
    } else {
        return cast(T)cmath.tanh(cast(double)x);
    }
}

/**
    Computes hyperbolic arc-sine of the given value.

    Params:
        x = The value
    
    Returns:
        The hyperbolic arc-sine of $(D x).
*/
pragma(inline, true)
T asinh(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_asin!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_asinhf(x);
        else static if (is(T == double))
            return __builtin_asinh(x);
        else static if (is(T == real))
            return __builtin_asinhl(x);
    } else {
        return cast(T)cmath.asinh(cast(double)x);
    }
}

/**
    Computes hyperbolic arc-cosine of the given value.

    Params:
        x = The value
    
    Returns:
        The hyperbolic arc-cosine of $(D x).
*/
pragma(inline, true)
T acosh(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_acosh!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_acoshf(x);
        else static if (is(T == double))
            return __builtin_acosh(x);
        else static if (is(T == real))
            return __builtin_acoshl(x);
    } else {
        return cast(T)cmath.acosh(cast(double)x);
    }
}

/**
    Computes hyperbolic arc-tangent of the given value.

    Params:
        x = The value
    
    Returns:
        The hyperbolic arc-tangent of $(D x).
*/
pragma(inline, true)
T atanh(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_atanh!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_atanhf(x);
        else static if (is(T == double))
            return __builtin_atanh(x);
        else static if (is(T == real))
            return __builtin_atanhl(x);
    } else {
        return cast(T)cmath.atanh(cast(double)x);
    }
}

/**
    Computes the nearest integer value lower in magnitude than
    the given value.

    Params:
        x = The value
    
    Returns:
        The nearest integer value lower in magnitude than $(D x).
*/
pragma(inline, true)
T trunc(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_trunc!T(x);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_truncf(x);
        else static if (is(T == double))
            return __builtin_trunc(x);
        else static if (is(T == real))
            return __builtin_truncl(x);
    } else {
        return cast(T)cmath.trunc(cast(double)x);
    }
}

@("trunc")
unittest {
    assert(trunc(1.5) == 1);
    assert(trunc(1.9999991) == 1);
    assert(trunc(1.0000001) == 1);
    assert(trunc(0.9999991) == 0);

    assert(trunc(cast(float)1.0) == 1);
    assert(trunc(cast(double)1.0) == 1);
    assert(trunc(cast(real)1.0) == 1);
}

/**
    Computes the nearest integer value, rounded away from 0.

    Params:
        value = Input value
    
    Returns:
        The nearest integer value to $(D x).
*/
T round(T)(T value) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_round!T(value);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_roundf(value);
        else static if (is(T == double))
            return __builtin_round(value);
        else static if (is(T == real))
            return __builtin_roundl(value);
    } else {
        return cast(T)cmath.round(cast(double)value);
    }
}

@("round")
unittest {
    assert(round(0.0) == 0);
    assert(round(0.25) == 0);
    assert(round(0.5) == 1);
    assert(round(0.95) == 1);

    assert(round(cast(float)1.0) == 1);
    assert(round(cast(double)1.0) == 1);
    assert(round(cast(real)1.0) == 1);
}

/**
    Computes the nearest integer value lower than the given value.

    Params:
        value = Input value
    
    Returns:
        The nearest integer value lower than $(D x).
*/
pragma(inline, true)
T floor(T)(T value) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_floor!T(value);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_floorf(value);
        else static if (is(T == double))
            return __builtin_floor(value);
        else static if (is(T == real))
            return __builtin_floorl(value);
    } else {
        return cast(T)cmath.floor(cast(double)value);
    }
}

@("floor")
unittest {
    assert(floor(0.0) == 0);
    assert(floor(0.25) == 0);
    assert(floor(0.5) == 0);
    assert(floor(0.95) == 0);

    assert(floor(cast(float)1.0) == 1);
    assert(floor(cast(double)1.0) == 1);
    assert(floor(cast(real)1.0) == 1);
}

/**
    Computes the nearest integer value lower than the given value.

    Params:
        value = Input value
    
    Returns:
        The nearest integer value lower than $(D x).
*/
pragma(inline, true)
T ceil(T)(T value) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_ceil!T(value);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_ceilf(value);
        else static if (is(T == double))
            return __builtin_ceil(value);
        else static if (is(T == real))
            return __builtin_ceill(value);
    } else {
        return cast(T)cmath.ceil(cast(double)value);
    }
}

@("ceil")
unittest {
    assert(ceil(0.0) == 0);
    assert(ceil(0.25) == 1);
    assert(ceil(0.5) == 1);
    assert(ceil(0.95) == 1);
    
    assert(ceil(cast(float)1.0) == 1);
    assert(ceil(cast(double)1.0) == 1);
    assert(ceil(cast(real)1.0) == 1);
}

/**
    Computes the absolute value for the given value.

    Params:
        value = the value
    
    Returns:
        The absolute value of $(D value)
*/
pragma(inline, true)
T abs(T)(T value) if (__traits(isScalar, T)) {
    static if (__traits(isFloating, T)) {
        version(LDC) {
            return llvm_fabs!T(value);
        } else version(GNU) {
            static if (is(T == float))
                return __builtin_fabsf(value);
            else static if (is(T == double))
                return __builtin_fabs(value);
            else static if (is(T == real))
                return __builtin_fabsl(value);
        } else {
            return cast(T)cmath.fabs(cast(double)value);
        }
    } else {
        return value < 0 ? -value : value;
    }
}

@("abs")
unittest {
    foreach(i; 0..100) {
        assert(abs(cast(float)-i) == cast(float)i);
    }
    
    assert(abs(cast(float)1.0) == 1);
    assert(abs(cast(double)1.0) == 1);
    assert(abs(cast(real)1.0) == 1);
}

/**
    Rounds the given value to the nearest integer,
    using the current rounding mode.

    Params:
        x = The value
    
    Returns:
        $(D x) rounded to the nearest integer 
        in respect to rounding mode.
*/
pragma(inline, true)
T rint(T)(T x) if (__traits(isFloating, T)) {
    version(LDC) {
        return llvm_rint!T(value);
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_rintf(value);
        else static if (is(T == double))
            return __builtin_rint(value);
        else static if (is(T == real))
            return __builtin_rintl(value);
    } else {
        return cast(T)cmath.rint(cast(double)value);
    }
}

/**
    Computes n * 2$(SUPERSCRIPT exp).

    Params:
        n =     The value
        exp =   The exponent
    
    Returns:
        $(D value * pow(exp, 2)).
*/
pragma(inline, true)
T ldexp(T)(T n, int exp) if (__traits(isFloating, T)) {
    version(LDC) {
        enum RealFormat { ieeeSingle, ieeeDouble, ieeeExtended, ieeeQuadruple }

             static if (T.mant_dig ==  24) enum realFormat = RealFormat.ieeeSingle;
        else static if (T.mant_dig ==  53) enum realFormat = RealFormat.ieeeDouble;
        else static if (T.mant_dig ==  64) enum realFormat = RealFormat.ieeeExtended;
        else static if (T.mant_dig == 113) enum realFormat = RealFormat.ieeeQuadruple;
        else static assert(false, "Unsupported format for " ~ T.stringof);

        version (LittleEndian)
        {
            enum MANTISSA_LSB = 0;
            enum MANTISSA_MSB = 1;
        }
        else
        {
            enum MANTISSA_LSB = 1;
            enum MANTISSA_MSB = 0;
        }

        static if (realFormat == RealFormat.ieeeExtended)
        {
            alias S = int;
            alias U = ushort;
            enum sig_mask = U(1) << (U.sizeof * 8 - 1);
            enum exp_shft = 0;
            enum man_mask = 0;
            version (LittleEndian)
                enum idx = 4;
            else
                enum idx = 0;
        }
        else
        {
            static if (realFormat == RealFormat.ieeeQuadruple || realFormat == RealFormat.ieeeDouble && double.sizeof == size_t.sizeof)
            {
                alias S = long;
                alias U = ulong;
            }
            else
            {
                alias S = int;
                alias U = uint;
            }
            static if (realFormat == RealFormat.ieeeQuadruple)
                alias M = ulong;
            else
                alias M = U;
            enum sig_mask = U(1) << (U.sizeof * 8 - 1);
            enum uint exp_shft = T.mant_dig - 1 - (T.sizeof > U.sizeof ? U.sizeof * 8 : 0);
            enum man_mask = (U(1) << exp_shft) - 1;
            enum idx = T.sizeof > U.sizeof ? MANTISSA_MSB : 0;
        }
        enum exp_mask = (U.max >> (exp_shft + 1)) << exp_shft;
        enum int exp_msh = exp_mask >> exp_shft;
        enum intPartMask = man_mask + 1;

        import core.checkedint : adds;
        alias _expect = llvm_expect;

        enum norm_factor = 1 / T.epsilon;
        T vf = n;

        auto u = (cast(U*)&vf)[idx];
        int e = (u & exp_mask) >> exp_shft;
        if (_expect(e != exp_msh, true))
        {
            if (_expect(e == 0, false)) // subnormals input
            {
                bool overflow;
                vf *= norm_factor;
                u = (cast(U*)&vf)[idx];
                e = int((u & exp_mask) >> exp_shft) - (T.mant_dig - 1);
            }
            bool overflow;
            exp = adds(exp, e, overflow);
            if (_expect(overflow || exp >= exp_msh, false)) // infs
            {
                static if (realFormat == RealFormat.ieeeExtended)
                {
                    return vf * T.infinity;
                }
                else
                {
                    u &= sig_mask;
                    u ^= exp_mask;
                    static if (realFormat == RealFormat.ieeeExtended)
                    {
                        version (LittleEndian)
                            auto mp = cast(ulong*)&vf;
                        else
                            auto mp = cast(ulong*)((cast(ushort*)&vf) + 1);
                        *mp = 0;
                    }
                    else
                    static if (T.sizeof > U.sizeof)
                    {
                        (cast(U*)&vf)[MANTISSA_LSB] = 0;
                    }
                }
            }
            else
            if (_expect(exp > 0, true)) // normal
            {
                u = cast(U)((u & ~exp_mask) ^ (cast(typeof(U.init + 0))exp << exp_shft));
            }
            else // subnormal output
            {
                exp = 1 - exp;
                static if (realFormat != RealFormat.ieeeExtended)
                {
                    auto m = u & man_mask;
                    if (exp > T.mant_dig)
                    {
                        exp = T.mant_dig;
                        static if (T.sizeof > U.sizeof)
                            (cast(U*)&vf)[MANTISSA_LSB] = 0;
                    }
                }
                u &= sig_mask;
                static if (realFormat == RealFormat.ieeeExtended)
                {
                    version (LittleEndian)
                        auto mp = cast(ulong*)&vf;
                    else
                        auto mp = cast(ulong*)((cast(ushort*)&vf) + 1);
                    if (exp >= ulong.sizeof * 8)
                        *mp = 0;
                    else
                        *mp >>>= exp;
                }
                else
                {
                    m ^= intPartMask;
                    static if (T.sizeof > U.sizeof)
                    {
                        int exp2 = exp - int(U.sizeof) * 8;
                        if (exp2 < 0)
                        {
                            (cast(U*)&vf)[MANTISSA_LSB] = ((cast(U*)&vf)[MANTISSA_LSB] >> exp) ^ (m << (U.sizeof * 8 - exp));
                            m >>>= exp;
                            u ^= cast(U) m;
                        }
                        else
                        {
                            exp = exp2;
                            (cast(U*)&vf)[MANTISSA_LSB] = (exp < U.sizeof * 8) ? m >> exp : 0;
                        }
                    }
                    else
                    {
                        m >>>= exp;
                        u ^= cast(U) m;
                    }
                }
            }
            (cast(U*)&vf)[idx] = u;
        }
        return vf;
    } else version(GNU) {
        static if (is(T == float))
            return __builtin_ldexpf(n, exp);
        else static if (is(T == double))
            return __builtin_ldexp(n, exp);
        else static if (is(T == real))
            return __builtin_ldexpl(n, exp);
    } else {
        return cast(T)cmath.ldexp(cast(double)n, exp);
    }
}



//
//          EXTRAS
//
private:

version(LDC) {

    // Trigonometry
    pragma(LDC_intrinsic, "llvm.tan.f#")
    T llvm_tan(T)(T val) if (__traits(isFloating, T));
    
    pragma(LDC_intrinsic, "llvm.asin.f#")
    T llvm_asin(T)(T val) if (__traits(isFloating, T));
    
    pragma(LDC_intrinsic, "llvm.acos.f#")
    T llvm_acos(T)(T val) if (__traits(isFloating, T));
    
    pragma(LDC_intrinsic, "llvm.atan.f#")
    T llvm_atan(T)(T val) if (__traits(isFloating, T));

    pragma(LDC_intrinsic, "llvm.atan2.f#")
    T llvm_atan2(T)(T y, T x) if (__traits(isFloating, T));
    
    
    pragma(LDC_intrinsic, "llvm.sinh.f#")
    T llvm_sinh(T)(T val) if (__traits(isFloating, T));
    
    pragma(LDC_intrinsic, "llvm.cosh.f#")
    T llvm_cosh(T)(T val) if (__traits(isFloating, T));
    
    pragma(LDC_intrinsic, "llvm.tanh.f#")
    T llvm_tanh(T)(T val) if (__traits(isFloating, T));
    
    

    pragma(LDC_intrinsic, "llvm.asinh.f#")
    T llvm_asinh(T)(T val) if (__traits(isFloating, T));
    
    pragma(LDC_intrinsic, "llvm.acosh.f#")
    T llvm_acosh(T)(T val) if (__traits(isFloating, T));
    
    pragma(LDC_intrinsic, "llvm.atanh.f#")
    T llvm_atanh(T)(T val) if (__traits(isFloating, T));
}