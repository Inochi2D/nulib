/**
    Win32 Threading Bindings

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.win32;

//
//          BINDINGS
//
version(Windows):
extern(Windows):

alias fp2_t = extern(D) void function(void* userData) @nogc;
alias fp_t = extern(Windows) uint function(void*);

/// A critical section object.
struct CRITICAL_SECTION {
    void*   DebugInfo;
    int     LockCount;
    int     RecursionCount;
    void*   OwningThread;
    void*   LockSemaphore;
    size_t  SpinCount;
}

enum WAIT_OBJECT_0    = 0;
enum WAIT_ABANDONED_0 = 128;
enum CREATE_SUSPENDED = 0x00000004;
enum INFINITE = 0xFFFFFFFF;

extern int CloseHandle(void*) @trusted @nogc nothrow;
extern void DeleteCriticalSection(CRITICAL_SECTION*) @trusted @nogc nothrow;
extern uint InitializeCriticalSectionAndSpinCount(CRITICAL_SECTION*, uint) @trusted @nogc nothrow;
extern void EnterCriticalSection(CRITICAL_SECTION*) @trusted @nogc nothrow;
extern void LeaveCriticalSection(CRITICAL_SECTION*) @trusted @nogc nothrow;
extern uint TryEnterCriticalSection(CRITICAL_SECTION*) @trusted @nogc nothrow;
extern void Sleep(int) @trusted @nogc nothrow;
extern int ResumeThread(void*) @trusted @nogc nothrow;
extern int SuspendThread(void*) @trusted @nogc nothrow;
extern int GetCurrentThreadId() @trusted @nogc nothrow;
extern void* GetCurrentProcess() @trusted @nogc nothrow;
extern uint GetProcessId(void*) @trusted @nogc nothrow;
extern bool TerminateProcess(void*, uint) @trusted @nogc nothrow;
extern void* CreateSemaphoreA(void*, int, int, void*) @trusted @nogc nothrow;
extern uint ReleaseSemaphore(void*, int, int*) @trusted @nogc nothrow;
extern uint WaitForSingleObject(void*, uint) @trusted @nogc nothrow;
extern ptrdiff_t _beginthreadex(void*, uint, fp_t, void*, uint, uint*) @trusted @nogc nothrow;
