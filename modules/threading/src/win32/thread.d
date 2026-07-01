/**
    Windows Threads

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.win32.thread;
import nulib.threading.win32;
import nulib.threading.thread;
import numem;

version(Windows):

/**
    Win32 implementation of native threading.
*/
class Win32Thread : NativeThread {
private:
@nogc:
    uint suspendCount_;
    shared(ThreadContext) ctx_;
    void* handle_;
    uint tid_;

public:

    // Destruction is not handled by the class destructor.
    ~this() @trusted nothrow { }

    /**
        Creates a new thread from a context.

        Params:
            ctx = The thread context.
    */
    this(ThreadContext ctx) @trusted nothrow {
        this.ctx_ = cast(shared(ThreadContext))ctx;
        nu_atomic_store_32(this.suspendCount_, 1);
        handle_ = cast(void*)_beginthreadex(
            null, 
            0u, 
            &_nu_thread_win32_entry, 
            cast(void*)&ctx_,
            CREATE_SUSPENDED,
            &tid_
        );

        assert(handle_, "Failed to create thread!");
    }

    /**
        Creates a thread by providing an existing handle.
    */
    this(void* handle) @trusted {
        this.handle_ = handle;
    }
    
    /**
        Whether the thread is currently running.
    */
    override @property bool isRunning() @trusted => nu_atomic_load_32(suspendCount_) == 0;

    /**
        ID of the thread.
    */
    override @property ThreadId tid() @safe => cast(ThreadId)tid_;

    /**
        Starts the given thread.
    */
    override
    void start() @trusted {
        if (!handle_)
            return;
        
        if (nu_atomic_load_32(suspendCount_) != 0) {
            int sv = ResumeThread(handle_);
            if (sv >= 0)
                nu_atomic_store_32(suspendCount_, sv-1);
        }
    }

    /**
        Forcefully cancels the thread, stopping execution.

        This is not a safe operation, as it may lead to memory
        leaks and corrupt state. Only use when ABSOLUTELY neccesary.
    */
    override
    void cancel() @system {
        if (!handle_)
            return;
        
        if (nu_atomic_load_32(suspendCount_) == 0) {
            int sv = SuspendThread(handle_);
            if (sv >= 0)
                nu_atomic_store_32(suspendCount_, sv+1);
        }
    }

    /**
        Waits for the thread to finish execution.
    
        Params:
            timeout = How long to wait for the thread to exit.
            rethrow = Whether execptions thrown in the thread should be rethrown.
    */
    override
    bool join(uint timeout, bool rethrow) @trusted {

        // Thread is already suspended.
        if (nu_atomic_load_32(suspendCount_) != 0)
            return true;

        // Thread is not suspended, wait for it.
        if (WaitForSingleObject(handle_, timeout == 0 ? INFINITE : timeout) == WAIT_OBJECT_0) {
            nu_atomic_store_32(suspendCount_, 1);
            
            CloseHandle(handle_);
            this.handle_ = null;

            if (rethrow && ctx_.ex)
                throw cast(Exception)ctx_.ex;
            
            return true;
        }
        
        return false;
    }
}

extern(C) export
NativeThread _nu_native_thread_create(ThreadContext ctx) @trusted @nogc nothrow {
    return nogc_new!Win32Thread(ctx);
}

extern(C) export
ThreadId _nu_thread_self_tid() @trusted @nogc nothrow {
    return cast(ThreadId)GetCurrentThreadId();
}

extern(C) export
void _nu_thread_sleep(uint ms) @trusted @nogc nothrow {
    Sleep(ms);
}

extern(Windows)
uint _nu_thread_win32_entry(void* threadContext) @trusted nothrow @nogc {
    ThreadContext* context = cast(ThreadContext*)(threadContext);
    try {
        (cast(fp2_t)context.callback)(context.userData);
    } catch(Exception ex) {
        context.ex = ex;
    }
    return 0;
}