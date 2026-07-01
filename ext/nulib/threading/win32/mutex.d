/**
    Windows Mutexes

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.win32.mutex;
import nulib.threading.mutex;
import numem.object;

version(Windows):

/**
    A Win32 Mutex        
*/
class Win32Mutex : NativeMutex {
private:
@nogc:
    CRITICAL_SECTION* handle_;

public:

    /// Destructor
    ~this() nothrow {
        DeleteCriticalSection(handle_);
        nu_free(handle_);
    }

    /**
        Constructs a mutex.
    */
    this() nothrow {
        this.handle_ = cast(CRITICAL_SECTION*)nu_malloc(CRITICAL_SECTION.sizeof);

        // Cargo-culting the spin-count in WTF::Lock
        // See: https://webkit.org/blog/6161/locking-in-webkit/
        cast(void)InitializeCriticalSectionAndSpinCount(handle_, 40);
    }

    /**
        Increments the internal lock counter.
    */
    override
    void lock() nothrow @trusted {
        EnterCriticalSection(handle_);
    }

    /**
        Tries to increment the internal lock counter.

        Returns:
            $(D true) if the mutex was locked,
            $(D false) otherwise.
    */
    override
    bool tryLock() nothrow @trusted {
        return TryEnterCriticalSection(handle_) != 0;
    }

    /**
        Decrements the internal lock counter,
        If the counter reaches 0, the lock is released.
    */
    override
    void unlock() nothrow @trusted {
        LeaveCriticalSection(handle_);
    }
}

/**
    Creates a native mutex for the given platform.

    Returns:
        A new $(D NativeMutex) on success, $(D null)
        if mutexes aren't supported on the platform. 
*/
extern(C) export NativeMutex _nu_native_mutex_create() @nogc {
    return nogc_new!Win32Mutex();
}

//
//              IMPLEMENTATION DETAILS
//
private:

//
//          BINDINGS
//
version(Windows) {
    extern(Windows) @nogc nothrow {
        /// A critical section object.
        struct CRITICAL_SECTION {
            void*   DebugInfo;
            int     LockCount;
            int     RecursionCount;
            void*   OwningThread;
            void*   LockSemaphore;
            size_t  SpinCount;
        }

        extern void DeleteCriticalSection(CRITICAL_SECTION*);
        extern uint InitializeCriticalSectionAndSpinCount(CRITICAL_SECTION*, uint);
        extern void EnterCriticalSection(CRITICAL_SECTION*);
        extern void LeaveCriticalSection(CRITICAL_SECTION*);
        extern uint TryEnterCriticalSection(CRITICAL_SECTION*);
    }
}