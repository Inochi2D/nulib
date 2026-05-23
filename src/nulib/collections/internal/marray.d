module nulib.collections.internal.marray;
import numem.core.memory : nu_is_overlapping;
import numem.core.hooks;
import numem.core.traits;
import numem;

/**
    A managed array with utilities for range manipulation
*/
struct ManagedArray(T, bool ownsMemory = true) {
    alias memory this;

    // Backing slice of the vector.
    T[] memory;

    // Memory capacity of the slice.
    size_t capacity = 0;

    // Resizing algorithm
    pragma(inline, true)
    void resize(size_t length) @trusted {
        
        // Early exit.
        if (length == memory.length)
            return;

        // Reserve if over-allocating for the current
        // size.
        if (length > capacity)
            this.reserve(length);

        // If the new length is lower than the prior length
        // Destroy the prior allocated objects.
        if (length < memory.length) {
            this.deleteRange(memory.ptr[length..memory.length]);
        }

        // If it's bigger, initialize the memory in the new range.
        if (length > memory.length) {
        
            // Initialize the newly prepared memory by
            // bliting T.init to it.
            nogc_initialize(memory.ptr[memory.length..length]);
        }

        memory = memory.ptr[0..length];
    }

    // Reservation algorithm
    pragma(inline, true)
    void reserve(size_t length) @trusted {
        if (length == 0) {
            memory = memory.nu_resize(0);
            this.capacity = 0;
            return;
        }

        // Resize down if neccesary.
        size_t sliceSize = memory.length;
        if (sliceSize > length) {
            sliceSize = length;
            this.reserve(sliceSize);
        }

        memory = memory.nu_resize(length)[0..sliceSize];
        this.capacity = length;
    }

    // Range deletion algorithm.
    pragma(inline, true)
    void deleteRange(U)(U[] range) if (is(Unconst!U == Unconst!T)) {
        static if (ownsMemory) {
            nogc_delete(range);
        } else {
            nogc_initialize(range);
        }

        // Handle array rearrangement.
        ptrdiff_t startIdx = cast(ptrdiff_t)(range.ptr - memory.ptr);
        ptrdiff_t endIdx = startIdx+range.length;
        size_t leftoverCount = (memory.length-endIdx);
        if (startIdx >= 0) {
            
            // Shift old memory in
            if (endIdx < memory.length) {
                nu_memmove(cast(void*)&memory[startIdx], cast(void*)&memory[endIdx], leftoverCount*T.sizeof);
            }

            // Hide the now invalid memory.
            memory = memory[0..startIdx+leftoverCount];
        }
    }

    // Checks whether src or dst is moving into our memory slice.
    // This is used in moveRange to allow for overlapping moves.
    pragma(inline, true)
    bool isMovingIntoSelf(U)(U[] dst, U[] src) if (is(Unconst!U == Unconst!T)) {
        return 
            nu_is_overlapping(cast(void*)memory.ptr, memory.length*T.sizeof, cast(void*)dst.ptr, dst.length*T.sizeof) && 
            nu_is_overlapping(cast(void*)memory.ptr, memory.length*T.sizeof, cast(void*)src.ptr, src.length*T.sizeof);
    }

    // Checks whether src or dst is moving into our memory slice.
    // This is used in moveRange to allow for overlapping moves.
    pragma(inline, true)
    bool isMovingIntoSelf(U)(U[] src) if (is(Unconst!U == Unconst!T)) {
        return 
            nu_is_overlapping(cast(void*)memory.ptr, memory.length*T.sizeof, cast(void*)src.ptr, src.length*T.sizeof);
    }

    // Range move algorithm.
    pragma(inline, true)
    void moveRange(U)(U[] dst, U[] src) if (is(Unconst!U == Unconst!T)) {

        // Handle overlapping moves.
        if (isMovingIntoSelf(dst, src)) {
            src = rangeCopy(src);
            static if (hasElaborateMove!T) {
                nogc_move(dst, src);
            } else {
                nogc_copy(dst, src);
            }
            src = src.nu_resize(0);
            return;
        }

        // Non-overlapping moves.
        static if (hasElaborateMove!T) {
            nogc_move(dst, src);
        } else {
            nogc_copy(dst, src);
        }
    }

    // Take ownership of memory store.
    pragma(inline, true)
    T[] take() {
        auto mem = memory;
        this.memory = null;
        return mem;
    }

    // Reverses the contents of the array
    pragma(inline, true)
    void reverse() {
        alias U = Unconst!(T)[];

        if (memory.length == 0)
            return;
        
        auto mmemory = cast(U)memory;
        foreach(i; 0..memory.length/2) {
            auto a = memory[i];
            auto b = memory[$-(i+1)];

            mmemory[i] = b;
            mmemory[$-(i+1)] = a;
        }
    }

    // Flips the endianness of the elements within the array.
    pragma(inline, true)
    void flipEndian() {
        alias U = Unconst!(T);
        alias UX = ubyte[U.sizeof];

        static if (U.sizeof > 1) {
            
            import nulib.memory.endian : nu_etoh, ALT_ENDIAN;
            cast(void)nu_etoh!(UX, ALT_ENDIAN)(cast(UX[])memory[0..$]);
        }
    }
}

// Checks whether 2 memory ranges overlap.
pragma(inline, true)
bool isOverlapping(T, U)(T[] dst, U[] src) if (is(Unconst!U == Unconst!T)) {
    return 
        nu_is_overlapping(cast(void*)dst.ptr, dst.length*T.sizeof, cast(void*)src.ptr, src.length*T.sizeof);
}

// Reverses the contents of the array
pragma(inline, true)
void arrReverse(T)(T[] memory) {
    alias U = Unconst!(T)[];

    if (memory.length == 0)
        return;

    U tmp;
    foreach(i; 0..memory.length/2) {
        size_t lhs = i;
        size_t rhs = memory.length-i;

        tmp = (cast(U[])memory)[lhs];
        (cast(U[])memory)[lhs] = (cast(U[])memory)[rhs];
        (cast(U[])memory)[rhs] = tmp;
    }
}

// Flips the endianness of the elements within the array.
pragma(inline, true)
void arrFlipEndian(T)(T[] memory) {
    static if (T.sizeof > 1) {
        alias U = Unconst!(T)[];
        import nulib.memory.endian : nu_etoh, ALT_ENDIAN;
    
        cast(void)nu_etoh!(U[], ALT_ENDIAN)(cast(U[])memory);
    }
}

// Range copy for moves internally.
pragma(inline, true)
T[] rangeCopy(T)(T[] src) {
    alias UT = Unconst!(T)[];

    UT[] dst;
    dst = dst.nu_resize(src.length);
    static if (hasElaborateMove!T) {
        nogc_move(cast(UT)dst[0..$], cast(UT)src[0..$]);
    } else {
        nogc_copy(cast(UT)dst[0..$], cast(UT)src[0..$]);
    }
    
    return cast(T[])dst;
}