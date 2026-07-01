/**
    POSIX Implementation for NativeMutex

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.posix.threading.mutex;
import nulib.threading.mutex;
import core.sys.posix.pthread;
import numem;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;
else version (VisionOS)
    version = Darwin;

version(Posix):

/**
    Native implementation of a mutually exclusive lock.
*/
class PosixMutex : NativeMutex {
private:
@nogc:
    pthread_mutex_t handle_;

public:

    ~this() nothrow {
        auto rc = pthread_mutex_destroy(&handle_);
        assert(!rc, "Failed to destroy mutex!");
    }

    this() nothrow {
        pthread_mutexattr_t attr = void;
        auto rc = pthread_mutexattr_init(&attr);
        assert(!rc, "Failed to create mutex!");

        if (!rc) {
            rc = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
            assert(!rc, "Failed to create mutex!");

            rc = pthread_mutex_init(&handle_, &attr);
            assert(!rc, "Failed to create mutex!");
        }

        rc = pthread_mutexattr_destroy(&attr);
        assert(!rc, "Failed to create mutex!");
    }

    /**
        Increments the internal lock counter.
    */
    override
    void lock() nothrow @trusted {
        if (pthread_mutex_lock(&handle_) == 0)
            return;
        
        assert(0, "Failed to lock mutex!");
    }

    /**
        Tries to increment the internal lock counter.

        Returns:
            $(D true) if the mutex was locked,
            $(D false) otherwise.
    */
    override
    bool tryLock() nothrow @trusted {
        return pthread_mutex_trylock(&handle_) == 0;
    }

    /**
        Decrements the internal lock counter,
        If the counter reaches 0, the lock is released.
    */
    override
    void unlock() nothrow @trusted {
        if (pthread_mutex_unlock(&handle_) == 0)
            return;

        assert(0, "Failed to unlock mutex!");
    }
}

extern(C) export
NativeMutex _nu_native_mutex_create() @trusted @nogc nothrow {
    return nogc_new!PosixMutex();
}