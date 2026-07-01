/**
    Win32 Implementation for nulib.threading.internal.semaphore

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.win32.semaphore;
import nulib.threading.semaphore;
import numem;

version(Windows):

/**
    Native implementation of a semaphore.
*/
class Win32Semaphore : NativeSemaphore {
private:
@nogc:
    void* handle_;
    
public:

    /// Destructor
    ~this() nothrow {
        auto rc = CloseHandle(handle_);
        assert(rc, "Failed to destroy semaphore!");
    }

    /**
        Constructs a new Win32 Semaphore.
    */
    this(uint count) nothrow {
        this.handle_ = CreateSemaphoreA(null, count, int.max, null);
        assert(handle_, "Failed to create semaphore!");
    }

    /**
        Signals the semaphore.

        Note:
            Control is not transferred to the waiter.
    */
    override
    void signal() nothrow @trusted {
        cast(void)ReleaseSemaphore(handle_, 1, null);
    }

    /**
        Suspends the thread until the semaphore is signaled,
        or the timeout is reached.

        Params:
            timeout =   Timeout in miliseconds to block the 
                        calling thread before giving up.

        Returns:
            $(D true) if the semaphore was signaled in time,
            $(D false) otherwise.
    */
    override
    bool await(ulong timeout = 0) nothrow @trusted {
        if (timeout == 0) {
            return WaitForSingleObject(handle_, INFINITE) == WAIT_OBJECT_0;
        }

        long timeLeft = timeout;
        uint rc;
        while(timeLeft > 0) {
            rc = WaitForSingleObject(handle_, timeLeft >= uint.max ? uint.max-1 : cast(uint)timeLeft);
            if(rc == WAIT_OBJECT_0)
                return true;

            timeLeft -= uint.max-1;
        }
        return false;
    }

    /**
        Checks if the semaphore is signalled then
        awaits on it if is.

        Returns:
            $(D true) if the semaphore was signalled,
            $(D false) otherwise.
    */
    override
    bool tryAwait() nothrow @trusted {
        return WaitForSingleObject(handle_, 0) == WAIT_OBJECT_0;
    }
}

extern(C) export
NativeSemaphore _nu_native_semaphore_create(uint count) @trusted @nogc nothrow {
    return nogc_new!Win32Semaphore(count);
}

//
//          BINDINGS
//
extern(Windows) @nogc nothrow:

extern void* CreateSemaphoreA(void*, int, int, void*);
extern uint ReleaseSemaphore(void*, int, int*);