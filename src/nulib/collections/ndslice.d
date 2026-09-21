/**
    N-dimensional slices.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.collections.ndslice;
import numem.core.meta;

/**
    An N-dimensional slice over a contiguous range of memory.
*/
struct ndslice(T, size_t N) {
private:
@nogc:
    T* ptr_;
    size_t[N] strides_;
    size_t[N] lengths_;

public:

    /**
        Type of the ndslice.
    */
    alias SelfType = typeof(this);

    /**
        Type sequence consisting of N amounts of lengths.
    */
    alias IndexArgs = AliasSeq!(typeof(size_t[N].init.tupleof));

    /**
        Type sequence consisting of N amounts of slice lengths.
    */
    alias IndexAssignArgs = AliasSeq!(typeof(size_t[2][N].init.tupleof));

    /**
        Side lengths of the ndslice
    */
    @property size_t[N] length() => lengths_;

    /**
        Contiguous length of the slice.
    */
    @property size_t clength() {
        size_t r = lengths_[0];
        static foreach(i; 1..N)
            r *= lengths_[i];
        return r;
    }

    /**
        Constructs a ndslice over a linear slice.

        Params:
            slice =     The slice to construct
            lengths =   Side lengths of the slice.
    */
    this(inout(T)[] slice, IndexArgs lengths) pure nothrow {
        this.ptr_ = cast(T*)slice.ptr;
        this.lengths_[0] = lengths[0];
        this.strides_[0] = lengths[0];

        static foreach(i; 1..N) {
            this.lengths_[i] = lengths[i];
            this.strides_[i] = strides_[i-1]*lengths[i];
        }
    }

    /**
        Obtains the length of the slice

        Returns:
            The number of rows in this vector.
    */
    size_t opDollar(size_t dim)() const {
        return lengths_[dim];
    }

    /**
        Assigns the given value to all elements of the slice.

        Params:
            value = the value to assign.
    */
    void opIndexAssign(T value) @trusted {
        foreach(ref item; this)
            item = value;
    }

    /**
        Assigns the given value to all elements of the slice.

        Params:
            value = the value to assign.
            args = The dimensional offsets into the slice.
    */
    void opIndexAssign(T value, IndexArgs args) @trusted {
        this.opIndex(args) = value;
    }

    /**
        Index the slice.

        Params:
            args = The dimensional offsets into the slice.
    */
    ref inout(T) opIndex(IndexArgs args) @trusted inout pure {
        static foreach(i; 0..N) assert(args[i] <= lengths_[i], "Index outside bounds of array.");
        inout(T)* iptr = ptr_;
        
        // Add offsets.
        static if (N > 1) {
            static foreach(i; 1..args.length) {
                iptr += strides_[i-1]*args[i];
            }
        }
        return iptr[args[0]];
    }

    /**
        Allows iterating over the slice.

        Params:
            dg = The function to call on each iteration.
    */
    int opApply(scope int delegate(IndexArgs, ref T) dg) @nogc @trusted {

        // Type-casted nogc delegate.
        alias dg_t = int delegate(IndexArgs, ref T) @nogc @trusted;
        auto dgn = cast(dg_t)dg;

        size_t tlen = clength;
        size_t c;
        size_t[N] i;

        while (c < tlen) {
            int result = dgn(i.tupleof, this.opIndex(i.tupleof));
            if (result)
                return result;

            i[0]++;
            c++;
            static foreach(d; 1..N) {
                if (i[d-1] >= lengths_[d-1]) {
                    i[d-1] = 0;
                    i[d]++;
                }
            }
        }
        return 0;
    }

    /// ditto
    int opApply(scope int delegate(ref T) dg) @nogc @trusted {

        // Type-casted nogc delegate.
        alias dg_t = int delegate(ref T) @nogc @trusted;
        auto dgn = cast(dg_t)dg;

        size_t tlen = clength;
        size_t c;
        size_t[N] i;

        while (c < tlen) {
            int result = dgn(this.opIndex(i.tupleof));
            if (result)
                return result;

            i[0]++;
            c++;
            static foreach(d; 1..N) {
                if (i[d-1] >= lengths_[d-1]) {
                    i[d-1] = 0;
                    i[d]++;
                }
            }
        }
        return 0;
    }

    /// ditto
    int opApplyReverse(scope int delegate(IndexArgs, ref T) dg) @nogc @trusted {

        // Type-casted nogc delegate.
        alias dg_t = int delegate(IndexArgs, ref T) @nogc @trusted;
        auto dgn = cast(dg_t)dg;

        size_t tlen = clength;
        size_t c = tlen;
        ptrdiff_t[N] i;
        static foreach(ix; 0..N)
            i = cast(ptrdiff_t)lengths_[ix]-1;

        while (c > 0) {
            int result = dgn(i.tupleof, this.opIndex(i.tupleof));
            if (result)
                return result;

            i[0]--;
            static foreach(d; 1..N) {
                if (i[d-1] < 0) {
                    i[d-1] = lengths_[d-1]-1;
                    i[d]--;
                }
            }
            c--;
        }
        return 0;
    }

    /// ditto
    int opApplyReverse(scope int delegate(ref T) dg) @nogc @trusted {

        // Type-casted nogc delegate.
        alias dg_t = int delegate(ref T) @nogc @trusted;
        auto dgn = cast(dg_t)dg;

        size_t tlen = clength;
        size_t c = tlen;
        ptrdiff_t[N] i;
        static foreach(ix; 0..N)
            i = cast(ptrdiff_t)lengths_[ix]-1;

        while (c > 0) {
            int result = dgn(this.opIndex(i.tupleof));
            if (result)
                return result;

            i[0]--;
            static foreach(d; 1..N) {
                if (i[d-1] < 0) {
                    i[d-1] = lengths_[d-1]-1;
                    i[d]--;
                }
            }
            c--;
        }
        return 0;
    }
}

@("ndslice: linear-to-slice")
unittest {
    uint[32*32] a = 0;
    auto slice = ndslice!(uint, 2)(a, 32, 32);

    slice[] = 32;
    slice[0, 0] = 1;
    
    assert(slice[0, 0] == 1);
    assert(slice[0, 1] == 32);
}