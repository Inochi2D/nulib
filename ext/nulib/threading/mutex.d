/**
    Mutually Exclusive Locks

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.mutex;
import nulib.threading.internal.mutex;
import numem;

/**
    A mutually exclusive lock.
*/
class Mutex : NuObject {
private:
@nogc:
    NativeMutex mutex_;

public:

    /**
        The native implementation defined handle of the mutex.
    */
    final @property NativeMutex nativeHandle() => mutex_;

    /// Destructor
    ~this() {
        nogc_delete(mutex_);
    }

    /**
        Constructs a new Mutex.
    */
    this() {
        this.mutex_ = NativeMutex.create();
        enforce(mutex_, "Mutex is not supported on this platform.");
    }

    /**
        Increments the internal lock counter.
    */
    void lock() nothrow @safe {
        mutex_.lock();
    }

    /**
        Tries to increment the internal lock counter.

        Returns:
            $(D true) if the mutex was locked,
            $(D false) otherwise.
    */
    bool tryLock() nothrow @safe {
        return mutex_.tryLock();
    }

    /**
        Decrements the internal lock counter,
        If the counter reaches 0, the lock is released.
    */
    void unlock() nothrow @safe {
        mutex_.unlock();
    }
}

/**
    Wrapper for a system-native mutex.    
*/
abstract
class NativeMutex : NuObject {
public:
@nogc:
    
    /**
        Creates a native mutex for the given platform.

        Returns:
            A new $(D NativeMutex) on success, $(D null)
            if mutexes aren't supported on the platform.    
    */
    pragma(mangle, "_nu_native_mutex_create")
    extern(C) static NativeMutex create();

    /**
        Increments the internal lock counter.
    */
    abstract void lock() nothrow @trusted;

    /**
        Tries to increment the internal lock counter.

        Returns:
            $(D true) if the mutex was locked,
            $(D false) otherwise.
    */
    abstract bool tryLock() nothrow @trusted;

    /**
        Decrements the internal lock counter,
        If the counter reaches 0, the lock is released.
    */
    abstract void unlock() nothrow @trusted;
}

@("lock and unlock")
unittest {
    Mutex m = nogc_new!Mutex();
    m.lock();
    m.unlock();
    nogc_delete(m);
}