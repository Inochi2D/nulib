/**
    Dynamic Arrays

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.collections.vector;
import nulib.collections.internal.marray;
import numem.core.hooks;
import numem.core.traits;
import numem;

/**
    A vector which owns the memory it contains.
*/
alias vector(T) = VectorImpl!(T, true);

/**
    A vector which does not own the memory it contains.
*/
alias weak_vector(T) = VectorImpl!(T, false);

/**
    A @nogc dynamic array.
*/
struct VectorImpl(T, bool ownsMemory = true) {
@nogc:
private:
    alias SelfType = typeof(this);
    ManagedArray!(T, ownsMemory) memory;

public:
    alias value this;

    /**
        Gets the internal memory slice.
    */
    @property T[] value() @trusted nothrow pure { return memory; }

    /**
        The length of the vector
    */
    @property size_t length() const @safe nothrow { return memory.length; }

    /**
        The capacity of the vector.
    */
    @property size_t capacity() const @safe nothrow { return memory.capacity; }

    /**
        Whether the vector is empty.
    */
    @property bool empty() const @safe nothrow { return memory.length == 0; }

    /**
        The length of the vector, in bytes.
    */
    @property size_t usage() @safe nothrow { return memory.length*T.sizeof; }

    /**
        Gets a pointer to the first element of the
        vector.
    */
    @property T* ptr() @system nothrow { return memory.ptr; }

    /**
        Gets a pointer to the first element of the vector.

        If the vector is empty, the first element will be null.
    */
    @property T* front() @system nothrow { return empty ? null : &memory[0]; }

    /**
        Gets a pointer to the last element of the vector.

        If the vector is empty, the last element will be null.
    */
    @property T* back() @system nothrow { return empty ? null : &memory[$-1]; }

    ~this() {

        // This essentially frees the memory.
        memory.reserve(0);
        memory.capacity = 0;
    }

    /**
        Creates a new vector from a slice.

        Params:
            rhs = slice to copy or move data from.

        Notes:
            Elements will either be copied or moved out of the
            source slice. Pointers will only be weakly referenced.
            If said pointers were allocated with the GC, they may be
            collected!
    */
    this(T[] rhs) @system {
        if (__ctfe) {
            memory.memory = rhs;
            memory.capacity = rhs.length;
        } else {
            static if (hasElaborateMove!T) {
                memory.resize(rhs.length);
                nogc_move(memory, rhs);
            } else {
                memory.resize(rhs.length);
                nogc_copy(memory, rhs);
            }
        }
    }

    /**
        Copy-constructor

        Params:
            rhs = slice to copy or move data from.
    */
    this(ref return scope inout(SelfType) rhs) @trusted {
        if (__ctfe) {
            this = cast(typeof(this))rhs;
        } else {
            static if (hasElaborateMove!T) {
                memory.resize(rhs.length);
                nogc_move(memory.memory, rhs);
            } else {
                memory.resize(rhs.length);
                nogc_copy(memory.memory, cast(SelfType)rhs);
            }
        }
    }

    /**
        Constructs a new vector with $(D reserved) amount of 
        elements worth of memory reserved.

        Params:
            reserved = How many elements of memory to reserve.
    */
    this(size_t reserved) {
        if (__ctfe) { } else {
            this.reserve(reserved);
        }
    }

    /**
        Take ownership of the memory owned by the vector.

        Returns:
            The memory which was owned by the vector,
            the vector is reset in the process.
    */
    T[] take() {
        return memory.take();
    }

    /**
        Flips the endianness of the vector's contents.

        Note:
            This is no-op for 8-bit elements.

        Returns:
            The vector instance.
    */
    auto ref flipEndian() {
        memory.flipEndian();
        return this;
    }

    /**
        Reverses the contents of the vector

        Returns:
            The vector instance.
    */
    auto ref reverse() {
        memory.reverse();
        return this;
    }

    /**
        Clears the vector, removing all elements from it.
    */
    void clear() @safe {
        memory.reserve(0);
    }

    /**
        Attempts to reserve memory in the vector.

        Reserve can *only* grow the allocation; not shrink it.
    */
    auto ref reserve(size_t newSize) {
        if (newSize > memory.capacity)
            memory.reserve(newSize);
        
        return this;
    }

    /**
        Resizes the vector.
    */
    auto ref resize(size_t newSize) {
        memory.resize(newSize);
        return this;
    }

    /**
        Pops the front element of the vector.
    */
    void popFront() {
        if (!empty) {
            memory.deleteRange(memory[0..1]);
        }
    }

    /**
        Pops the back element of the vector.
    */
    void popBack() {
        if (!empty) {
            if (memory.length == 1) {
                this.clear();
                return;
            }

            memory.deleteRange(memory[$-1..$]);
        }
    }

    /**
        Removes an element from the vector matching the given element.
    */
    void remove(T element) {
        foreach_reverse(i; 0..memory.length) {

            // NOTE:    DRuntime's opEquals implementation is not nogc
            //          as such we need to check whether we can do an equals comparison
            //          in a nogc context.
            //          Otherwise, we try calling opEquals directly, if that fails we try
            //          the `is` operator, and finally if that fails we assert at compile-time.
            static if (is(typeof(() @nogc { return T.init == T.init; }))) {
                if (memory[i] == element) {
                    this.removeAt(i);
                    return;
                }
            } else static if (is(typeof(() @nogc { return T.init.opEquals(T.init); }))) {
                if (memory[i].opEquals(element)) {
                    this.removeAt(i);
                    return;
                }
            } else static if (is(typeof(() @nogc { return T.init is T.init; }))) {
                if (memory[i] is element) {
                    this.removeAt(i);
                    return;
                }
            } else static assert(0, "Failed to find a nogc comparison method!");
        }
    }

    /**
        Removes the element at the given index.
    */
    void removeAt(size_t i) {
        if (i >= 0 && i < memory.length) {
            memory.deleteRange(memory[i .. i+1]);
        }
    }

    /**
        Removes the elements at the given index with the given
        element count.
    */
    void removeAt(size_t i, size_t count) {
        if (i >= 0 && i+count < memory.length) {
            memory.deleteRange(memory[i .. i+count]);
        }
    }

    /**
        Inserts a value into the vector.

        Params:
            value =     The value to insert.
            offset =    The offset to insert the value at.
    */
    void insert(T value, size_t offset) {
        assert(offset < memory.length, "Offset is past the end of the vector");

        // Resize
        size_t ogLength = memory.length;
        memory.resize(memory.length+1);

        // Move & Insert
        memory.moveRange(memory[offset+1..ogLength+1], memory[offset..ogLength]);
        static if (hasElaborateMove!T) {
            memory.memory[offset] = value.move();
        } else {
            memory.memory[offset] = value;
        }
    }

    /**
        Inserts a value into the vector.

        Params:
            values =    The values to insert.
            offset =    The offset to insert the values at.
    */
    void insert(T[] values, size_t offset) {
        assert(offset < memory.length, "Offset is past the end of the vector");

        // Resize
        size_t ogLength = memory.length;
        memory.resize(memory.length+values.length);

        // Move & Insert
        memory.moveRange(memory[offset+values.length..ogLength+values.length], memory[offset..ogLength]);
        memory.moveRange(memory[offset..offset+values.length], values);
    }

    /**
        Append a $(D T) to the vector.

        Params:
            value = The value to append.
    */
    void opOpAssign(string op = "~")(auto ref T value) @trusted {
        memory.resize(length+1);

        static if (hasElaborateMove!T) {
            memory.memory[$-1] = value.move();
        } else {
            memory.memory[$-1] = value;
        }
    }

    /**
        Append a range to the vector.

        Params:
            other = the other range to append.
    */
    void opOpAssign(string op = "~")(T[] other) @trusted {
        size_t start = memory.length;

        // Self-intersecting move.
        if (memory.isMovingIntoSelf(other)) {
            other = rangeCopy(other);
            
            memory.resize(memory.length+other.length);
            memory.moveRange(memory[start..$], other[0..$]);
            other = other.nu_resize(0);
        }

        // Basic move.
        memory.resize(memory.length+other.length);
        memory.moveRange(memory[start..$], other[0..$]);
    }
}

@("vector-of-strings")
unittest {
    import nulib.string : nstring;
    vector!nstring strs;
    strs ~= nstring("Hello, world!");
    strs ~= nstring("Hello, world!");
    strs ~= nstring("Hello, world!");
    strs ~= nstring("Hello, world!");
    strs ~= nstring("Hello, world!");
    strs ~= nstring("Hello, world!");

    strs ~= strs;

    import std.stdio : writeln;
    foreach(ref str; strs) {
        assert(str == "Hello, world!");
    }
}

@(".reverse()")
unittest {
    vector!int numbers = [1, 2, 3, 4];
    assert(numbers.reverse() == [4, 3, 2, 1]);
}

@(".flipEndian()")
unittest {
    vector!ushort numbers = [0xFF00, 0x00FF];
    assert(numbers.flipEndian() == [0x00FF, 0xFF00]);
}

@(".flipEndian().reverse()")
unittest {
    vector!ushort numbers = [0xFF00, 0x0FF0, 0x00FF];
    assert(numbers.flipEndian().reverse() == [0xFF00, 0xF00F, 0x00FF]);
}

@(".removeAt(index)")
unittest {
    vector!int numbers = [1, 0, 2, 3, 4];

    numbers.removeAt(1);
    assert(numbers == [1, 2, 3, 4]);
}

@(".removeAt(index, count)")
unittest {
    vector!int numbers = [0, 1, 2, 3, 4];

    numbers.removeAt(1, 2);
    assert(numbers == [0, 3, 4]);
}

@(".remove(element)")
unittest {
    vector!int numbers = [0, 1, 255, 2, 3, 4];

    numbers.remove(255);
    assert(numbers == [0, 1, 2, 3, 4]);
}

@(".insert(element)")
unittest {
    vector!int numbers = [0, 1, 2, 3, 4];

    numbers.insert(255, 2);
    assert(numbers == [0, 1, 255, 2, 3, 4]);
}

@(".insert(elements)")
unittest {
    vector!int numbers = [0, 1, 2, 3, 4];

    numbers.insert([255, 255, 255], 2);
    assert(numbers == [0, 1, 255, 255, 255, 2, 3, 4]);
}

@(".flipEndian() nothrow struct")
unittest {
    static
    struct Test {
        ulong a;
        ~this() @nogc nothrow { }
    }

    Test testA = Test(0xF00FF00FF00FF00F);
    Test testB = Test(0x0FF00FF00FF00FF0);
    vector!Test testStructs = [testA, testB];
    assert(testStructs.flipEndian() == [testB, testA]);
}