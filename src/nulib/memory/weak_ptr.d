/**
    Weak pointers

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.memory.weak_ptr;
import nulib.memory.internal;
import numem.core.traits;
import numem;

/**
    A weak pointer.

    Weak pointers point to memory owned by shared_ptr or unique_ptr.
    They do not own the memory allocation and said allocation may
    become $(D null) at any point.

    Make sure to check the validity of the underlying value using
    $(D isValid)!

    See_Also:
        $(D nulib.memory.shared_ptr.shared_ptr)
        $(D nulib.memory.unique_ptr.unique_ptr)
*/
struct weak_ptr(T) {
@nogc:
private:
    __refcount_t!(T)* ptr = null;

package(nulib.memory):

    /**
        Constructs a weak pointer from an internal refcount object.
    */
    this(__refcount_t!T* ptr) @system {
        this.ptr = ptr;
        ptr.retain!false;
    }

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
            ptr.release!false;
            ptr = null;
        }
    }

    /**
        Copy Constructor.
    */
    this(ref return scope inout(typeof(this)) src) {
        this.ptr = cast(typeof(ptr))src.ptr;
        this.ptr.retain!false;
    }
}