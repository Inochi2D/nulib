/**
    Small Vectors

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.collections.smallvector;
import nulib.collections.internal.cmp;
import numem.core.hooks;
import numem.core.traits;
import numem;

/**
    A vector with a limited amount of slots stored on the stack.

    If $(D N) is not defined, the default will be the max amount of
    elements that fits within 64 bytes.

    Note:
        Small vectors always use weak references to their elements,
        use $(D nogc_delete) to delete individual elements.

    Params:
        T = The type of the elements in the vector
        N = The amount of elements to store on the stack.
*/
struct SmallVector(T, size_t N = 64/T.sizeof) {
private:
@nogc:
    T[N] data_;
    size_t length_;

public:
    alias data this;

    /**
        Type of the vector.
    */
    alias SelfType = typeof(this);

    /**
        The length of the vector
    */
    @property size_t length() const @safe nothrow { return length_; }

    /**
        The capacity of the vector.
    */
    @property size_t capacity() const @safe nothrow { return N; }

    /**
        Whether the vector is empty.
    */
    @property bool empty() const @safe nothrow { return length_ == 0; }

    /**
        The length of the vector, in bytes.
    */
    @property size_t usage() @safe nothrow { return length_*T.sizeof; }

    /**
        Slice of the data stored in the vector.
    */
    @property T[] data() @trusted nothrow pure { return data_[0..length_]; }

    /**
        Gets a pointer to the first element of the
        vector.
    */
    @property T* ptr() @system nothrow { return &data_[0]; }

    /**
        Gets a pointer to the first element of the vector.

        If the vector is empty, the first element will be null.
    */
    @property T* front() @system nothrow { return &data_[0]; }

    /**
        Gets a pointer to the last element of the vector.

        If the vector is empty, the last element will be null.
    */
    @property T* back() @system nothrow { return &data_[length_-1]; }

    /**
        Creates a new vector from a slice.

        Params:
            values = Values to assign.
    */
    static foreach(I; 1..N) {
        this(T[I] values) {
            this.data_[0..I] = values;
            this.length_ = I;
        }
    }

    /**
        Copy-constructor

        Params:
            rhs = slice to copy or move data from.
    */
    this(ref return scope SelfType rhs) @trusted {
        this.data_ = rhs.data_;
        this.length_ = rhs.length_;
    }

    /**
        Copy-constructor

        Params:
            rhs = slice to copy or move data from.
    */
    this(ref return scope inout(SelfType) rhs) @trusted {
        this.data_ = rhs.data_;
        this.length_ = rhs.length_;
    }

    /**
        Move-constructor

        Params:
            rhs = slice to copy or move data from.
    */
    this(return scope inout(SelfType) rhs) @trusted {
        this.data_ = rhs.data_;
        this.length_ = rhs.length_;
    }

    /**
        Constructs a new vector with $(D reserved) amount of 
        elements worth of memory reserved.

        Params:
            reserved = How many elements of memory to reserve.
    */
    this(size_t reserved) {
        assert(reserved < N, "Out of small vector range!");
        this.length_ = reserved;
    }

    /**
        Finds the given element in the array and returns
        its position.

        Params:
            element = The element to find.

        Returns:
            The position of the element, or $(D -1)
            if the element couldn't be found.
    */
    ptrdiff_t find(T element) {
        foreach(i; 0..length_) {
            if (nu_equals(data_[i], element))
                return i;
        }
        return -1;
    }

    /**
        Clears the vector, removing all elements from it.
    */
    void clear() @trusted {
        nogc_zeroinit(this.data_[]);
        this.length_ = 0;
    }

    /**
        Swaps this vector's internal state with another's.

        Params:
            other = The other vector to swap state with.
    */
    void swap(ref SelfType other) {
        nu_swap(this, other);
    }

    /**
        Pushes an element to the front of the vector.

        Params:
            value = The value to push.
    */
    void pushFront()(auto ref T value) @trusted {
        assert(length_+1 < N, "small vector out of memory!");
        if (length_+1 < N) {
            this.length_++;
            nu_memmove(&data_[1], &data_[0], length_*T.sizeof);
            this.data_[0] = value;
        }
    }

    /**
        Pops the front element of the vector.
    */
    void popFront() {
        if (!empty) {
            nu_memmove(&data_[0], &data_[1], (length_-1)*T.sizeof);
            this.length_--;
        }
    }

    /**
        Pushes an element to the back of the vector.

        Params:
            value = The value to push.
    */
    void pushBack()(auto ref T value) @trusted {
        assert(length_+1 < N, "small vector out of memory!");
        if (length_+1 < N) {
            this.data_[length_] = value;
            this.length_++;
        }
    }

    /**
        Pops the back element of the vector.
    */
    void popBack() {
        if (!empty) {
            this.length_--;
        }
    }

    /**
        Removes an element from the vector matching the given element.

        Params:
            element = The element to remove.
    */
    void remove(T element) {
        auto idx = this.find(element);
        if (idx != -1) {
            this.removeAt(idx);
        }
    }

    /**
        Removes the element at the given index.

        Params:
            i = The index of the element to remove.
    */
    void removeAt(size_t i) {
        if (i >= 0 && i < length_) {
            nu_memmove(&data_[i], &data_[i+1], (N-i)*T.sizeof);
            this.length_--;
        }
    }

    /**
        Append a $(D T) to the vector.

        Params:
            value = The value to append.
    */
    pragma(inline, true)
    void opOpAssign(string op = "~")(auto ref T value) @trusted {
        this.pushBack(value);
    }
}

@("construct")
@nogc unittest {
    SmallVector!int a = [1, 2, 3];
    assert(a[0] == 1 && a[1] == 2 && a[2] == 3);
}

@("find")
@nogc unittest {
    SmallVector!int test = [1, 2, 3];
    assert(test.find(2) == 1);
    assert(test.find(24) == -1);
}

@("clear")
@nogc unittest {
    SmallVector!int test = [1, 2, 3];
    test.clear();
    assert(test.length == 0 && test.ptr[0] == 0);
}

@("swap")
@nogc unittest {
    SmallVector!int a = [1, 2, 3];
    SmallVector!int b = [3, 2, 1];

    assert(a[0] == 1 && b[0] == 3);
    a.swap(b);
    assert(a[0] == 3 && b[0] == 1);
}