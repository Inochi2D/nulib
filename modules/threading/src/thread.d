/**
    Threads

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.thread;
import numem;

/**
    Thread ID
*/
alias ThreadId = ptrdiff_t;

/**
    A thread context.
*/
struct ThreadContext {
    void* userData;
    void function(void* userData) callback;
    Exception ex;
}

/**
    A thread of execution.
*/
class Thread : NuObject {
private:
    NativeThread thread_;

protected:

    /**
        The native implementation defined handle of the thread.
    */
    final @property NativeThread nativeHandle() => thread_;
    
    /**
        Virtual function which may be overridden.
    */
    void onExecute() @nogc { }

    /**
        Creates a new thread executing the "onExecute"
        virtual function.
    */
    this() @nogc {
        ThreadContext context_;
        context_.userData = cast(void*)this;
        context_.callback = (void* ctx) { (cast(Thread)ctx).onExecute(); };
        this.thread_ = NativeThread.create(context_);
    }

public:

    /**
        Gets the ID of the calling thread.
    */
    pragma(mangle, "_nu_thread_self_tid")
    static @property ThreadId selfTid() @safe;

    /**
        The thread Id of the given thread.
    */
    final @property ThreadId tid() => thread_.tid();

    /**
        Whether the thread is currently running.
    */
    final @property bool isRunning() => thread_.isRunning();

    /**
        Creates a new thread.
    */
    this(void delegate() callback) @nogc @trusted {
        ThreadContext context_;
        context_.userData = callback.ptr;
        context_.callback = cast(void function(void* ptr) @nogc)callback.funcptr;
        this.thread_ = NativeThread.create(context_);
    }

    /**
        Creates a new thread.
    */
    this(void function() callback) @nogc @trusted {
        ThreadContext context_;
        context_.userData = cast(void*)this;
        context_.callback = cast(void function(void* ptr) @nogc)callback;
        this.thread_ = NativeThread.create(context_);
    }

    /**
        Creates a new thread.
    */
    this(T)(void function(T) callback, T data) @nogc @trusted {
        ThreadContext context_;
        context_.userData = cast(void*)data;
        context_.callback = cast(void function(void* ptr) @nogc)callback;
        this.thread_ = NativeThread.create(context_);
    }

    /**
        Makes the calling thread sleep for the specified amount
        of time.

        Params:
            ms = Miliseconds that the thread should sleep.
    */
    pragma(mangle, "_nu_thread_sleep")
    extern(C) static void sleep(uint ms) @nogc @safe;

    /**
        Starts executing the thread.

        Returns:
            This thread instance, allowing chaining.
    */
    Thread start() @nogc @safe {
        if (thread_)
            thread_.start();
        return this;
    }

    /**
        Forcefully cancels the thread, stopping execution.

        This is not a safe operation, as it may lead to memory
        leaks and corrupt state. Only use when ABSOLUTELY neccesary.

        Returns:
            This thread instance, allowing chaining.
    */
    Thread cancel() @nogc @system {
        if (thread_)
            thread_.cancel();
        return this;
    }

    /**
        Blocks the calling thread until the given thread
        completes.

        Params:
            timeout =   How long to wait for the thread to exit, 
                        0 to wait forever.
            rethrow =   Whether exections should be rethrown into
                        this thread.

        Returns:
            Whether the thread exited within the given time.
    */
    bool join(uint timeout = 0, bool rethrow = false) @nogc @safe {
        if (thread_)
            return thread_.join(timeout, rethrow);
        return false;
    }
}

/**
    Base class of native threading implementations.
*/
extern
abstract
class NativeThread : NuObject {
public:
@nogc:
    
    /**
        Creates a native thread for the given platform.

        Params:
            ctx = The thread context.

        Returns:
            A new $(D NativeThread) on success, $(D null)
            if thread aren't supported on the platform.    
    */
    pragma(mangle, "_nu_native_thread_create")
    extern(C) static NativeThread create(ThreadContext ctx);

    /**
        ID of the thread.    
    */
    abstract @property ThreadId tid() @safe;

    /**
        Whether the thread is currently running.
    */
    abstract @property bool isRunning() @safe;

    /**
        Starts the given thread.
    */
    abstract void start() @safe;

    /**
        Forcefully cancels the thread, stopping execution.

        This is not a safe operation, as it may lead to memory
        leaks and corrupt state. Only use when ABSOLUTELY neccesary.
    */
    abstract void cancel() @system;

    /**
        Waits for the thread to finish execution.
    
        Params:
            timeout = How long to wait for the thread to exit.
            rethrow = Whether execptions thrown in the thread should be rethrown.
    */
    abstract bool join(uint timeout, bool rethrow) @safe;
}

@("start & join")
unittest {
    import std.format : format;
    __gshared uint v = 0;

    Thread t = nogc_new!Thread(() {
        foreach(i; 0..100)
            v += 1;
    }).start();
    t.join();

    assert(t.nativeHandle, "Thread handle was null!");
    assert(v == 100, "Expected 100, got %s".format(v));
    nogc_delete(t);
}

@("isRunning")
unittest {
    Thread t = nogc_new!Thread(() {
        Thread.sleep(500);
    }).start();
    assert(t.isRunning);

    t.join();
    nogc_delete(t);
}

@("tid")
unittest {
    Thread t = nogc_new!Thread(() {
        Thread.sleep(500);
    }).start();
    assert(t.isRunning);
    assert(t.tid() != Thread.selfTid());

    t.join();
    nogc_delete(t);
}