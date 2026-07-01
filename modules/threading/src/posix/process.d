/**
    POSIX Implementation for NativeProcess

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.posix.threading.process;
import nulib.threading.process;
import numem;

version(Posix):

/**
    Native implementation of a POSIX Process.
*/
class PosixProcess : NativeProcess {
private:
@nogc:
    uint pid_;

public:

    /**
        The ID of the process.
    */
    override @property uint pid() @safe => pid_;

    /**
        Constructs a new PosixProcess.
    */
    this(uint pid) nothrow {
        this.pid_ = pid;
    }

    /**
        Kills the given process.

        Returns:
            $(D true) if the operation succeeded,
            $(D false) otherwise.
    */
    override
    bool kill() @safe {
        return cast(bool).kill(pid_, SIGTERM);
    }
}

extern(C) export
NativeProcess _nu_native_process_this() @nogc @trusted nothrow {
    return nogc_new!PosixProcess(.getpid());
}

//
//          BINDINGS
//
extern(C):

enum SIGTERM = 15;
extern uint getpid() @trusted @nogc nothrow;
extern int kill(uint, int) @trusted @nogc nothrow;