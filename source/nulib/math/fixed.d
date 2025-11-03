/**
    Nulib Fixed Point Math

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:
        Luna Nielsen
*/
module nulib.math.fixed;
import numem.casting;
import numem.core.traits;

/**
    Gets whether the provided value is a instance of $(D Fixed)
*/
enum isFixed(T) = is(T : Fixed!U, U...);

/**
    Fixed-point math type, fractional bits can be specified, but
    by default is split evenly; eg Fixed!int will be Q16.16

    Note:
        When converting a fixed-precision number to a floating point
        number, they may not be exact bit-for-bit equal; as such an
        approximate equals operation is recommended for comparing
        fixed point math with 
*/
struct Fixed(T, size_t FRACT_BITS = (8*(T.sizeof/2))) if (__traits(isIntegral, T) && !__traits(isUnsigned, T)) {
public:
@nogc nothrow:
    T data;
    
    /**
        Shorthand for this type
    */
    alias Self = typeof(this);
    
    /**
        Shorthand for the backing type
    */
    alias ValueT = T;
    
    /**
        How much to shift the data store in-operation.
    */
    enum T SHIFT = FRACT_BITS;
    
    /**
        Mask of fractional part
    */
    enum T FRACT_MASK = (cast(T)1LU << SHIFT) - 1;

    /**
        Division factor for the given precision of float.
    */
    enum FRACT_DIV(Y) = cast(Y)(1LU << SHIFT);
    
    /**
        Mask of integer part
    */
    enum T INT_MASK = ~FRACT_MASK;

    /**
        Max value of the fixed-precision value
    */
    enum Self min = Self.fromData(T.min);

    /**
        Max value of the fixed-precision value
    */
    enum Self max = Self.fromData(T.max);

    /**
        Creates a new instance from raw data.
    */
    static auto fromData(T data) {
        Self t;
        t.data = data;
        return t;
    }

    /**
        Constructor
    */
    this(Y)(Y other) {
        static if (__traits(isIntegral, Y)) {
            this.data = cast(T)(cast(T)other << SHIFT);
        } else static if (__traits(isFloating, Y)) {
            this.data = cast(T)(other * FRACT_DIV!Y);
        } else static if (isFixed!Y) {

            // Fast path for when you're just assigning between
            // the same type.
            static if (other.SHIFT == this.SHIFT) {
                this.data = cast(T)other.data;
                return;
            }


            // Shift integer part over so that we can realign it,
            // then add in the factional part from the other; making sure we cut out
            // any fractional part that doesn't fit within our own fractional space.
            T intPart = cast(T)(((other.data & other.INT_MASK) >> other.SHIFT) << SHIFT);
            T fractPart = cast(T)(other.data & other.FRACT_MASK);

            // This step aligns the fractional part with the size of the container.
            static if (other.SHIFT > SHIFT)
                fractPart = (fractPart >> (other.SHIFT-SHIFT));
            else 
                fractPart = (fractPart << (SHIFT-other.SHIFT));
            
            this.data = (intPart & INT_MASK) | (fractPart & FRACT_MASK);
        } else static assert(0, "Unsupported construction");
    }

    pragma(inline, true)
    Y opCast(Y)() const {
        static if (__traits(isIntegral, Y)) {
            return cast(Y)(data >> SHIFT);
        } else static if (__traits(isFloating, Y)) {
            return (cast(Y)data / FRACT_DIV!Y);
        } else static assert(0, "Unsupported cast.");
    }

    pragma(inline, true)
    size_t toHash() const @safe pure nothrow {
        return cast(size_t)this.data;
    }

    pragma(inline, true)
    bool opEquals(R)(const R other) const
    if (is(R : Fixed!T)) {
        return this.data == other.data;
    }

    pragma(inline, true)
    bool opEquals(R)(const R other) const
    if (__traits(isScalar, R)) {
        return this.data == Fixed!T(other).data;
    }

    pragma(inline, true)
    typeof(this) opBinary(string op, R)(const R rhs) const
    if (isFixed!R) {

        // Convert mismatched Fixed!T
        static if (R.SHIFT != SHIFT) {
            auto other = typeof(this)(rhs);
        } else static if (!is(typeof(R.data) == T)) {
            auto other = typeof(this).fromData(cast(T)rhs.data);
        } else {
            auto other = rhs;
        }

        // Move out to LONG
        long x = cast(long)data;
        long y = cast(long)other.data;
        long result;

        static if (op == "+") {

            result = x + y;
        } else static if (op == "-") {

            result = x - y;
        } else static if (op == "*") {
            
            result = (x * y) >> SHIFT;
        } else static if (op == "/") {
            static if (T.sizeof < 8 && R.sizeof < 8) {

                // NOTE:    For 32-bit and below division, 64 bit provides
                //          plenty of space to do the operation.
                result = (x << SHIFT) / y;
            } else {
                ulong signBit = 1LU << 63;
                ulong rem = x & ~signBit;
                ulong div = y & ~signBit;

                ulong quo = 0;
                int shift = SHIFT;
                while(rem && shift > 0) {
                    ulong d = rem / div;
                    rem %= div;
                    quo += d << shift;
                    
                    rem <<= 1;
                    --shift;
                }

                // NOTE:    Division generally takes up more space as such,
                //          this is the best way to get a mostly correct
                //          result for 64-bit fixed point numbers.
                result = (quo >> 1) | ((x & signBit) ^ (y & signBit));
            }
        } else static assert(0, "Operation not supported (yet)");

        return typeof(this).fromData(cast(T)result);
    }

    pragma(inline, true)
    typeof(this) opBinary(string op, R)(const R rhs) const
    if (__traits(isScalar, R)) {
        return this.opBinary!(op, Fixed!T)(Fixed!T(rhs));
    }
    
    pragma(inline, true)
    typeof(this) opOpAssign(string op, R)(const R rhs)
    if (isFixed!R) {
        this = this.opBinary!(op, R)(rhs);
        return this;
    }
    
    pragma(inline, true)
    typeof(this) opOpAssign(string op, R)(const R rhs)
    if (__traits(isScalar, R)) {
        this = typeof(this)(this.opBinary!(op, Fixed!T)(Fixed!T(rhs)));
        return this;
    }

    pragma(inline, true)
    typeof(this) opAssign(R)(const R rhs)
    if (!is(Unqual!R == Unqual!(typeof(this)))) {
        this.__ctor!R(rhs);
        return this;
    }
}

/**
    Q2.14 fixed-point number (16-bit)
*/
alias fixed2_14 = Fixed!(short, 14);

/**
    Q26.6 fixed-point number (32-bit)
*/
alias fixed26_6 = Fixed!(int, 6);

/**
    Q2.6 fixed-point number (8-bit)
*/
alias fixed2_6 = Fixed!(byte, 6);

/**
    Q8.8 fixed-point number (16-bit)
*/
alias fixed16 = Fixed!short;

/**
    Q16.16 fixed-point number (32-bit)
*/
alias fixed32 = Fixed!int;

/**
    Q32.32 fixed-point number (64-bit)
*/
alias fixed64 = Fixed!long;

@("fixed32: int->fixed32")
unittest {
    assert(cast(int)fixed32(16) == 16);
}

@("fixed32: fixed32->float")
unittest {
    import std.math : isClose;
    assert(isClose(cast(float)fixed32(32.32f), 32.32f));
}

@("fixed32: +")
unittest {
    assert(fixed32(31) + 1 == 32);
    assert(fixed32(1.5) + 1.5 == 3);
}

@("fixed32: -")
unittest {
    assert(fixed32(32) - 1 == 31);
    assert(fixed32(1.5) - 0.5 == 1.0);
}

@("fixed32: *")
unittest {
    assert(fixed32(16)*2 == 32);
    assert(fixed32(5.5)*2.5 == 5.5*2.5);
}

@("fixed32: /")
unittest {
    assert(fixed32(64) / 2 == 32);
}

@("fixed32: ctor fixed16")
unittest {
    assert(fixed32(fixed16(32)) == 32);
    assert(fixed32(fixed16(32.5)) == 32.5);
}

@("fixed16: +")
unittest {
    assert(fixed16(31) + 1 == 32);
}

@("fixed16: -")
unittest {
    assert(fixed16(32) - 1 == 31);
}

@("fixed16: *")
unittest {
    assert(fixed16(16)*2 == 32);
    assert(fixed16(5.5)*2.5 == 5.5*2.5);
}

@("fixed16: /")
unittest {
    assert(fixed16(64) / 2 == 32);
}

@("fixed16: ctor fixed32")
unittest {
    assert(fixed16(fixed32(32)) == 32);
    assert(fixed16(fixed32(32.5)) == 32.5);
}

@("fixed16: ctor fixed2_14")
unittest {
    assert(fixed16(fixed2_14(1.0)) == 1.0);
    assert(fixed16(fixed2_14(0.5)) == 0.5);
}




//
//          MATH OPERATIONS.
//


/**
    Computes the nearest integer value greater than the given value.

    Params:
        x = The value
    
    Returns:
        The nearest integer value greater than $(D x).
*/
T ceil(T)(T x) if (isFixed!T) {
    return T.fromData((x.data & T.INT_MASK) + (1 << T.SHIFT));
}

/**
    Computes the nearest integer value lower than the given value.

    Params:
        x = The value
    
    Returns:
        The nearest integer value lower than $(D x).
*/
T floor(T)(T x) if (isFixed!T) {
    return T.fromData(x.data & T.INT_MASK);
}

/**
    Computes the nearest integer value lower in magnitude than
    the given value.

    Params:
        x = The value
    
    Returns:
        The nearest integer value lower in magnitude than $(D x).
*/
T trunc(T)(T x) if (isFixed!T) {
    return T.fromData(x.data & T.INT_MASK);
}

/**
    Gets the fractional part of the value.

    Params:
        value = The value to get the fractional portion of

    Returns:
        The factional part of the given value.
*/
T fract(T)(T value) if (isFixed!T) {
    return T.fromData(value.data & T.FRACT_MASK);
}

@("fixed32: rounding")
unittest {
    assert(fixed32(1.5).trunc() == fixed32(1.0));
    assert(fixed32(1.5).floor() == fixed32(1.0));
    assert(fixed32(1.5).ceil() == fixed32(2.0));
    assert(fixed32(1.5).fract() == fixed32(0.5));
}