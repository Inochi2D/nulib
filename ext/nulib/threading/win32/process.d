/**
    Win32 Implementation for nulib.threading.internal.process

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.win32.process;
import nulib.threading.process;
import numem;

version(Windows):

class Win32Process : NativeProcess {
private:
@nogc:
    void* handle_;

public:

    /**
        The ID of the process.
    */
    override @property uint pid() @safe => GetProcessId(handle_);

    /**
        Constructs a new Win32Process.
    */
    this(void* handle) nothrow {
        this.handle_ = handle;
    }

    /**
        Kills the given process.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    override
    bool kill() @safe {
        return TerminateProcess(handle_, 0);
    }
}

extern(C) export
NativeProcess _nu_native_process_this() @nogc @trusted nothrow {
    return nogc_new!Win32Process(GetCurrentProcess());
}

//
//          BINDINGS
//
extern(Windows):
extern void* GetCurrentProcess() @trusted @nogc nothrow;
extern uint GetProcessId(void*) @trusted @nogc nothrow;
extern bool TerminateProcess(void*, uint) @trusted @nogc nothrow;