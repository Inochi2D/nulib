/**
    Posix Threads

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.posix.thread;
import nulib.threading.posix.semaphore;
import nulib.threading.thread;
import core.sys.posix.pthread;
import numem;

version(Posix):

struct PosixThreadContext {
    ThreadContext ctx;
    PosixSemaphore semaphore;
}

class PosixThread : NativeThread {
private:
@nogc:
    uint runRequests_;
    shared(PosixThreadContext) ctx_;
    pthread_t handle_;

public:

    ~this() nothrow {
        try {
            PosixSemaphore sem = cast(PosixSemaphore)nu_atomic_load_ptr(cast(void**)&ctx_.semaphore);
            if (sem) {
                nogc_delete(sem);
                nu_atomic_store_ptr(cast(void**)&ctx_.semaphore, null);
            }
        } catch (Exception ex) {
            // Let it leak.
        }
    }
    
    this(ThreadContext ctx) nothrow {
        this.ctx_ = cast(shared(PosixThreadContext))PosixThreadContext(
            ctx: ctx,
            semaphore: nogc_new!PosixSemaphore(0),
        );
    }

    /**
        ID of the thread.
    */
    override
    @property ThreadId tid() @trusted => cast(ThreadId)cast(void*)handle_;

    /**
        Whether the thread is currently running.
    */
    override
    @property bool isRunning() @trusted => nu_atomic_load_32(runRequests_) > 0;

    /**
        Starts the given thread.
    */
    override
    void start() @trusted {
        if (nu_atomic_load_32(runRequests_) == 0) {
            nu_atomic_add_32(runRequests_, 1);

            pthread_attr_t pattr = void;
            int err = pthread_attr_init(&pattr);
            assert(err == 0, "Failed to create thread!");
            pthread_create(&handle_, &pattr, &_nu_thread_posix_entry, cast(void*)&ctx_);
            pthread_attr_destroy(&pattr);
        }
    }

    /**
        Forcefully cancels the thread, stopping execution.

        This is not a safe operation, as it may lead to memory
        leaks and corrupt state. Only use when ABSOLUTELY neccesary.
    */
    override
    void cancel() @system {
        if (nu_atomic_load_32(runRequests_) > 0) {
            if (nu_atomic_sub_32(runRequests_, 1) == 1) {
                pthread_cancel(handle_);
                this.join(0, false);
            }
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
        if (!isRunning)
            return true;
        
        void* retv;
        if (timeout == 0) {
            if (pthread_join(handle_, &retv) == 0) {
                if (rethrow && ctx_.ctx.ex)
                    throw cast(Exception)ctx_.ctx.ex;

                return true;
            }
            return false;
        }

        PosixSemaphore sem = cast(PosixSemaphore)nu_atomic_load_ptr(cast(void**)&ctx_.semaphore);
        if (sem && sem.await(timeout)) {
            if (pthread_join(handle_, &retv) == 0) {
                if (rethrow && ctx_.ctx.ex)
                    throw cast(Exception)ctx_.ctx.ex;

                return true;
            }
            return false;
        }
        return false;
    }
}

extern(C) export
NativeThread _nu_native_thread_create(ThreadContext ctx) @trusted @nogc nothrow {
    return nogc_new!PosixThread(ctx);
}

extern(C) export
ThreadId _nu_thread_self_tid() @trusted @nogc nothrow {
    return cast(ThreadId)cast(void*)pthread_self();
}

extern(C) export
void _nu_thread_sleep(uint ms) @trusted @nogc nothrow {
    cast(void)usleep(cast(int)ms);
}

//
//          BINDINGS
//
extern(C) @nogc nothrow:

alias fp2_t = extern(D) void function(void* userData) @nogc;

void* _nu_thread_posix_entry(void* threadContext) @trusted nothrow @nogc {
    PosixThreadContext* context = cast(PosixThreadContext*)(threadContext);

    // Signal semaphore if it's still alive.
    PosixSemaphore sem = cast(PosixSemaphore)nu_atomic_load_ptr(cast(void**)&context.semaphore);
    try {
        (cast(fp2_t)context.ctx.callback)(context.ctx.userData);
        if (sem)
            sem.signal();
    } catch(Exception ex) {
        context.ctx.ex = ex;
    }
    return null;
}

extern int usleep(int) @trusted @nogc nothrow;
