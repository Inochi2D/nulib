/**
    Atomic Data Wrappers

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.atomic;
import numem;

/**
    Atomic pointer sized unsigned integer..
*/
alias asize_t = Atomic!size_t;

/**
    Atomic pointer sized signed integer..
*/
alias aptrdiff_t = Atomic!ptrdiff_t;

/**
    Atomic 32 bit floating point number.
*/
alias afloat = Atomic!float;

/**
    Atomic 32 bit unsigned integer.
*/
alias auint = Atomic!uint;

/**
    Atomic 32 bit signed integer.
*/
alias aint = Atomic!int;

/**
    Atomic 16 bit unsigned integer.
*/
alias aushort = Atomic!ushort;

/**
    Atomic 16 bit signed integer.
*/
alias ashort = Atomic!short;

/**
    Atomic 8 bit unsigned integer.
*/
alias aubyte = Atomic!ubyte;

/**
    Atomic 8 bit signed integer.
*/
alias abyte = Atomic!byte;

/**
    Wraps a type for atomic reading and writing.
*/
struct Atomic(T) if (T.sizeof <= (void*).sizeof) {
private:
@nogc:
    AtomicT value_;

    union AtomicT {
        T       ut;
        void*   ptr;
    }

public:
    alias value this;

    /**
        The value of the atomic type.
    */
    @property T value() {
        auto v = nu_atomic_load_ptr(cast(void**)&value_);
        return *cast(T*)&v;
    }
    @property void value(T value) {
        auto v = AtomicT(value);
        nu_atomic_store_ptr(cast(void**)&value_, v.ptr);
    }

    /**
        Constructs a new atomic value.
    */
    this(T value) {
        auto v = AtomicT(value);
        nu_atomic_store_ptr(cast(void**)&value_, v.ptr);
    }

    /**
        Atomic assignment
    */
    auto ref opAssign(Y)(inout(Y) value) if (is(T : Y)) {
        this.value = cast(T)value;
        return this;
    }

    /**
        Allows performing arithmetic operations on the given values.
    */
    auto ref opOpAssign(string op, Y)(inout(Y) value) if (__traits(isScalar, T) && is(T : Y)) {
        AtomicT oldv;
        AtomicT tmpv;
        oldv.ptr = nu_atomic_load_ptr(&value_.ptr);
        tmpv.ut = cast(T)value;

        mixin("tmpv.ut = oldv.ut ", op, " tmpv.ut;");
        nu_atomic_cmpxhg_ptr(&value_.ptr, oldv.ptr, tmpv.ptr);
        return this;
    }
}

@("atomic operations")
unittest {
    afloat f = 32.0;
    f += 10.0;
    assert(f == 42.0);

    f = 10.0;
    assert(f == 10.0);
}