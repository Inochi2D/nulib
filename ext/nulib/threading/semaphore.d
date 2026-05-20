/**
    Semaphores

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.semaphore;
import nulib.threading.internal.semaphore;
import numem;

/**
    A sempahore.
*/
class Semaphore : NuObject {
private:
@nogc:
    NativeSemaphore semaphore_;

public:

    /**
        The native implementation defined handle of the semaphore.
    */
    final @property NativeSemaphore nativeHandle() => semaphore_;

    /// Destructor
    ~this() {
        nogc_delete(semaphore_);
    }

    /**
        Constructs a new Mutex.
    */
    this(uint count = 0) {
        this.semaphore_ = NativeSemaphore.create(count);
        enforce(semaphore_, "Semaphore is not supported on this platform.");
    }

    /**
        Signals the semaphore.

        Note:
            Control is not transferred to the waiter.
    */
    void signal() {
        semaphore_.signal();
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
    bool await(ulong timeout = 0) {
        return semaphore_.await(timeout);
    }

    /**
        Checks if the semaphore is signalled then
        awaits on it if is.

        Returns:
            $(D true) if the semaphore was signalled,
            $(D false) otherwise.
    */
    bool tryAwait() {
        return semaphore_.tryAwait();
    }
}

@("signal and await")
unittest {
    Semaphore s = nogc_new!Semaphore();
    s.signal();
    assert(s.tryAwait());
    nogc_delete(s);
}