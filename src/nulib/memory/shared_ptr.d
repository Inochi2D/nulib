/**
    Shared Pointers

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.memory.shared_ptr;
import nulib.memory.weak_ptr;
import nulib.memory.internal;
import numem.core.traits;
import numem;

/**
    A shared pointer

    Shared pointers are a form of automatic reference counting. An internal 
    heap-allocated object stores a reference to the refcounted object.

    You may borrow weak references from $(D shared_ptr), these weak references
    may become invalid at $(I any) point, so make sure to check the state of the 
    object using $(D isValid).

    Example:
        ---
        auto wp = shared_new!int(42);
        if (wp.isValid) {
            // Use the value.
        }
        ---
    
    Threadsafety:
        The internal reference count kept by shared_ptr is $(B not) atomic.
        As such you should take care with accessing the value and refcount
        stored within.
    
    See_Also:
        $(D nulib.memory.unique_ptr.unique_ptr)
        $(D nulib.memory.weak_ptr.weak_ptr)
*/
struct shared_ptr(T) {
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
        Copy Constructor.
    */
    this(ref return scope inout(typeof(this)) src) {
        this.ptr = cast(typeof(ptr))src.ptr;
        this.ptr.retain!true;
    }

    /**
        Constructs a shared_ptr with the given memory address.
    */
    this(Ref!T ptr) @system {
        this.ptr = __refcount_t!(T).createNew(ptr);
    }

    /**
        Borrows a weak reference from the shared pointer.

        Returns:
            A new weak pointer, pointing to the same storage as
            the shared pointer.
    */
    weak_ptr!T borrow() @trusted {
        return weak_ptr!T(ptr);
    }
}

/**
    Creates a new shared pointer.

    Params:
        args =   The arguments to pass to $(D T)'s constructor.
    
    Returns:
        A shared pointer pointing to the newly allocated object.
*/
shared_ptr!T shared_new(T, Args...)(Args args) @trusted {
    return shared_ptr!T(nogc_new!T(args));
}

// Tests whether a shared pointer can be created.
@("shared_ptr: instantiation")
unittest {
    static
    class A { }
    shared_ptr!A p = shared_new!A();
    assert(p);
}

@("shared_ptr: deletion")
unittest {
    static bool dtest_v1;
    static bool dtest_v2;
    
    static
    class DeletionTest {
        ~this() { dtest_v1 = true; }
    }

    auto p = shared_new!DeletionTest();
    
    // Setup refcount debugging.
    p.ptr.userdata = &dtest_v2;
    p.ptr.onDeleted = (void* userdata) {
        bool* udbool = cast(bool*)userdata;
        *udbool = true;
    };

    // Borrowed copy.
    auto borrowed = p.borrow();
    

    // Delete old ref.
    nogc_delete(p);
    assert(dtest_v1);      // ~this() was run.

    nogc_delete(borrowed);
    assert(dtest_v2);      // __refcount_t was deleted.
}