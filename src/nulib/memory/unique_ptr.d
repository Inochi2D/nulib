/**
    Unique Pointers

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.memory.unique_ptr;
import nulib.memory.weak_ptr;
import nulib.memory.internal;
import numem.core.traits;
import numem;

public import numem.lifetime : nogc_move, move, moveTo;

/**
    A unique pointer.

    Unique pointers are a specialization of shared pointers, these pointers 
    can not be copied, only moved. $(D numem.core.lifetime) contains functions
    for achieving moves. 

    You may borrow weak references from $(D unique_ptr), these weak references
    may become invalid at $(I any) point, so make sure to check the state of the 
    object using $(D isValid).

    Example:
        ---
        static
        class A { }

        auto p = unique_new!A();
        auto b = move(p);

        assert(!p.isValid);
        assert(b.isValid);
        ---


    Threadsafety:
        The internal reference count kept by shared_ptr is $(B not) atomic.
        As such you should take care with accessing the value and refcount
        stored within.
    
    See_Also:
        $(D nulib.memory.shared_ptr.shared_ptr)
        $(D nulib.memory.weak_ptr.weak_ptr)
*/
struct unique_ptr(T) {
@nogc:
private:
    __refcount_t!(T)* ptr = null;

public:
    alias value this;

    /**
        The value stored within the smart pointer.
    */
    @property ref T value() @trusted nothrow {
        return ptr.get();
    }

    /**
        Whether the smart pointer value is still valid.
    */
    @property bool isValid() @trusted nothrow {
        return ptr && ptr.strongrefs > 0 && ptr.ptr !is null;
    }

    /// Destructor.
    ~this() @trusted { 
        if (ptr) {
            ptr.release!true; 
            ptr = null;
        }
    }

    /**
        Constructs a shared_ptr with the given memory address.
    */
    this()(Ref!T ptr) @system if(!is(Ref!T == typeof(this))) {
        this.ptr = __refcount_t!(T).createNew(ptr);
    }

    /**
        Disable copying.
    */
    @disable this()(ref return scope inout(typeof(this)) src);
    @disable this(this);

    /**
        Borrows a weak reference from the shared pointer.

        Returns:
            A new weak pointer, pointing to the same storage as
            the shared pointer.
    */
    weak_ptr!T borrow() @trusted {
        return weak_ptr!T(ptr);
    }

    /**
        Post-move operator.
    */
    void opPostMove(ref typeof(this) other) {
        other.ptr = null;
    }
}

/**
    Creates a new unique pointer.

    Params:
        args =   The arguments to pass to $(D T)'s constructor.
    
    Returns:
        A unique pointer pointing to the newly allocated object.
*/
unique_ptr!T unique_new(T, Args...)(Args args) @trusted {
    auto ptr = unique_ptr!T(nogc_new!T(args));

    // NOTE: This extra retain is needed since we can't
    //
    ptr.ptr.retain!true;
    return ptr; 
}

@("unique_ptr")
unittest {
    static
    class A { }

    auto p = unique_new!A();
    auto b = move(p);

    assert(!p.isValid);
    assert(b.isValid);

    // p.ptr should be null.
    assert(p.ptr is null);

    // Move to nowhere, destroying it.
    move(b);
    assert(!b.isValid);
}