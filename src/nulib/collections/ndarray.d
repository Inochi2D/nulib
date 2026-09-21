/**
    N-dimensional resizable arrays.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.collections.ndarray;
import nulib.collections.internal.marray;
import nulib.collections.internal.cmp;
import nulib.collections.ndslice;
import numem.core.traits;
import numem.core.meta;
import numem;

/**
    An N-dimensional array backed by contiguous memory.
*/
struct ndarray(T, size_t N) {
private:
@nogc:
    ManagedArray!(T, true) memory;
    size_t[N] strides_;
    size_t[N] lengths_;

public:

    /**
        Type of the ndarray.
    */
    alias SelfType = typeof(this);

    /**
        Type sequence consisting of N amounts of lengths.
    */
    alias IndexArgs = AliasSeq!(typeof(size_t[N].init.tupleof));

    /**
        Type sequence consisting of N amounts of slice ranges.
    */
    alias IndexAssignArgs = AliasSeq!(typeof(size_t[2][N].init.tupleof));

    /**
        Pointer to start of the ndarray.
    */
    @property inout(T)* ptr() inout pure => memory.memory.ptr;

    /**
        Slice of the data stored in the ndarray.
    */
    @property T[] data() @trusted nothrow pure { return memory; }

    /**
        Side lengths of the ndarray.
    */
    @property size_t[N] length() inout pure => lengths_;

    /**
        Contiguous length of the ndarray.
    */
    @property size_t clength() inout pure => memory.length;

    // Destructor
    ~this() {

        // This essentially frees the memory.
        memory.reserve(0);
        memory.capacity = 0;
    }

    /**
        Constructs a new ndarray

        Params:
            lengths = The side lengths of the array
    */
    this(IndexArgs lengths) {
        memory.resize(lengths.contiguousLengthOf());
        this.lengths_.tupleof = lengths;
        this.strides_.tupleof = lengths;
    }

    /**
        Resizes the array to the new given size.

        Any elements that are outside of the new size of the
        ndarray are freed.

        Params:
            lengths = The new side lengths of the ndarray
    */
    void resize(IndexArgs lengths) {

        // Handle resize from 0, no moving needs to be done.
        if (memory.length == 0) {
            memory.resize(lengths.contiguousLengthOf());
            this.lengths_.tupleof = lengths;
            this.strides_.tupleof = lengths;
            return;
        }

        // Take ownership of old memory.
        T[] tmp = memory.take();
        auto tmpslice = tmp.ndsliceof(lengths_.tupleof);

        // Create new allocation.
        memory.resize(lengths.contiguousLengthOf());
        this.lengths_.tupleof = lengths;
        this.strides_.tupleof = lengths;

        // Swap elements into the new allocation
        outer: foreach(coord; tmpslice.toIterND()) {
            static foreach(d; 0..N)
                if (coord[d] >= lengths[d])
                    continue outer;
            nu_swap(tmpslice[coord.tupleof], this[coord.tupleof]);
        }

        // Free old memory, freeing anything out of range.
        nu_freea(tmp);
    }

    /**
        Erases an element in the ndarray, replacing it with its 
        initial state.

        Params:
            element = The element to erase.
    */
    void erase(T element) {
        foreach_reverse(i; 0..memory.length) {
            if (nu_equals(memory[i], element)) {
                nogc_delete(memory[i]);
                return;
            }
        }
    }

    /**
        Erases an element in the ndarray, replacing it with its 
        initial state.

        Params:
            index = The index into the ndarray to erase.
    */
    void eraseAt(IndexArgs index) {
        static if (hasElaborateDestructor!T) {
            nogc_delete(this.opIndex(index));
        } else {
            nogc_initialize(this.opIndex(index));
        }
    }

    /**
        Swaps this ndarray's internal state with another's.

        Params:
            other = The other ndarray to swap state with.
    */
    void swap(ref SelfType other) {
        nu_swap(this.memory, other.memory);
        nu_swap(this.lengths_, other.lengths_);
        nu_swap(this.strides_, other.strides_);
    }

    /**
        Take ownership of the memory owned by the ndarray.

        Returns:
            The linear memory which was owned by the ndarray,
            the ndarray is reset in the process.
    */
    T[] take() {
        return memory.take();
    }

    /**
        Flips the endianness of the ndarray's contents.

        Note:
            This is no-op for 8-bit elements.

        Returns:
            The ndarray instance.
    */
    auto ref flipEndian() {
        memory.flipEndian();
        return this;
    }

    /**
        Reverses the contents of the ndarray

        Returns:
            The ndarray instance.
    */
    auto ref reverse() {
        memory.reverse();
        return this;
    }

    /**
        Clears the ndarray, removing all elements from it and reducing
        its size to 0.
    */
    void clear() @safe {
        memory.reserve(0);
        this.lengths_[] = 0;
        this.strides_[] = 0;
    }

    // Implement public shared slice interface.
    mixin NDSliceImpl!(T, N);
}

version(unittest) {

    // Makes checker test pattern.
    void makeTestPattern(ref ndarray!(int, 2) arr) {
        arr[] = 0;
        foreach(y; 0..arr.length[0]) {
            foreach(x; 0..arr.length[1]) {
                if ((y+x) % 2 && y % 2)
                    arr[x, y] = 1;
            }
        }
    }

    // Validates checker test pattern.
    bool validateTestPattern(ref ndarray!(int, 2) arr, int width, int height) {
        foreach(y; 0..width) {
            foreach(x; 0..height) {
                int s = ((y+x) % 2 && y % 2);
                if (arr[x, y] != s)
                    return false;
            }
        }
        return true;
    }
}

@("ndarray: create")
unittest {
    auto arr = ndarray!(int, 2)(32, 32);

    arr[] = 32;
    arr.eraseAt(15, 15);

    assert(arr[0, 0]    == 32);
    assert(arr[15, 15]  == 0);
}

@("ndarray: resize")
unittest {

    ndarray!(int, 2) arr2;
    arr2.resize(16, 16);

    arr2.makeTestPattern();
    assert(arr2.validateTestPattern(16, 16));

    // Resize up.
    arr2.resize(32, 32);
    assert(arr2.validateTestPattern(16, 16));
    assert(arr2[16, 16] == 0);

    // Resize down, with test pattern
    arr2.resize(8, 8);
    assert(arr2.validateTestPattern(8, 8));
}