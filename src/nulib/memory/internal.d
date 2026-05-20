/**
    Internal Implementation Details.

    You should not import this, as it does not expose any
    API outside outside of the nulib library.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.memory.internal;
import numem.core.traits;
import numem;

package(nulib.memory):

/**
    Container for refcounted memory.
*/
struct __refcount_t(T) {
@nogc:
    alias SelfType = typeof(this);
    alias SelfTypeRef = SelfType*;

    SelfTypeRef self;
    Ref!T ptr;

    size_t strongrefs;
    size_t weakrefs;

    // Debug utils for unit testing.
    version(unittest) {
        void* userdata;
        void function(void* userdata) onDeleted;
    }

    ~this() {
        ptr = null;
        self = null;

        version(unittest) {
            if (onDeleted) {
                onDeleted(userdata);
                onDeleted = null;
            }
        }
    }

    void retain(bool strong)() @trusted {
        static if (strong)
            strongrefs++;
        else
            weakrefs++;
    }

    void release(bool strong)() @trusted {
        static if (strong)
            strongrefs--;
        else
            weakrefs--;

        if (strongrefs == 0) {
            if (ptr)
                nogc_delete(ptr);
        
            if (weakrefs == 0 && self)
                nogc_delete(self);
        }
    }

    static SelfTypeRef createNew(Ref!T ptr) @trusted {
        SelfTypeRef selfptr = nogc_new!(SelfType);

        selfptr.self = selfptr;
        selfptr.ptr = ptr;
        selfptr.strongrefs = 1;
        return selfptr;
    }

    ref Unref!T get() @trusted nothrow {
        static if (is(Ref!T == T))
            return ptr;
        else
            return *ptr;
    }
}