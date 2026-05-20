/**
    Stacks

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.collections.stack;
import nulib.collections.internal.marray;
import numem.core.exception : enforce;
import numem.core.hooks;
import numem.core.traits;
import numem;

/**
    A stack which owns the memory it contains.
*/
alias stack(T) = StackImpl!(T, true);

/**
    A stack which does not own the memory it contains.
*/
alias weak_stack(T) = StackImpl!(T, false);

/**
    A @nogc dynamic stack
*/
struct StackImpl(T, bool ownsMemory = true) {
@nogc:
private:
    alias SelfType = typeof(this);
    ManagedArray!(T, ownsMemory) memory;

public:

    /**
        Gets the internal memory slice.
    */
    @property T[] values() @trusted nothrow pure { return memory; }

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

    ~this() {

        // This essentially frees the memory.
        memory.reserve(0);
        memory.capacity = 0;
    }

    /**
        Clears the vector, removing all elements from it.
    */
    void clear() @safe {
        memory.reserve(0);
    }

    /**
        Pushes an element onto the stack.

        Params:
            value = The value to push.
    */
    void push(T value) {
        memory.resize(length+1);

        static if (hasElaborateMove!T) {
            this.memory[$-1] = value.move();
        } else {
            this.memory[$-1] = value;
        }
    }

    /// ditto
    void opOpAssign(string op = "~")(auto ref T value) @trusted {
        memory.resize(length+1);

        static if (hasElaborateMove!T) {
            this.memory[$-1] = value.move();
        } else {
            this.memory[$-1] = value;
        }
    }

    /**
        Append a range to the stack.

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

    /**
        Pops a value from the stack.

        Returns:
            The value popped.

        Throws:
            An exception if the stack is empty.
    */
    T pop() {
        enforce(memory.length > 0, "Stack is empty.");
        
        T tmp = memory[$-1].move();
        memory.resize(length-1);
        return tmp;
    }

    /**
        Attempts to pop a value from the stack.

        Params:
            dst =   The variable to store the popped value in.

        Returns:
            Whether the operation succeeded.
    */
    bool tryPop(ref T dst) {
        if (memory.length == 0)
            return false;
        
        dst = memory[$-1].move();
        memory.resize(length-1);
        return true;
    }

    /**
        Peeks a value in the stack.

        Params:
            offset = The offset from the top of the stack to peek.
        
        Returns:
            The value peeked.

        Throws:
            An exception if an out-of-range access is attempted.
    */
    T peek(size_t offset) {
        enforce(memory.length-offset < memory.length, "Out of range access.");
        return memory[$-1];
    }

    /**
        Attempts to peek a value from the stack.

        Params:
            offset = The offset from the top of the stack to peek.
            dst =   The variable to store the peeked value in.

        Returns:
            Whether the operation succeeded.
    */
    bool tryPeek(size_t offset, ref T dst) {
        if (memory.length-offset > memory.length)
            return false;
        
        dst = memory[$-1];
        return true;
    }
}

@(".push(value)")
unittest {
    stack!int values;
    values.push(1);
    values.push(2);
    values.push(3);

    assert(values.values == [1, 2, 3]);
}

@(".pop()")
unittest {
    stack!int values;
    values.push(1);
    values.push(2);
    values.push(3);

    assert(values.values == [1, 2, 3]);
    assert(values.pop() == 3);
    assert(values.values == [1, 2]);
}

@(".peek(offset)")
unittest {
    stack!int values;
    values.push(1);
    values.push(2);
    values.push(3);

    assert(values.values == [1, 2, 3]);
    assert(values.peek(1) == 3);
    assert(values.values == [1, 2, 3]);
}
