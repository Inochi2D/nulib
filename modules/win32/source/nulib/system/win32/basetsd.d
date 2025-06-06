/**
 * Windows API header module
 *
 * Translated from MinGW API for MS-Windows 3.12
 *
 * Authors: Stewart Gordon
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_basetsd.d)
 */
module nulib.system.win32.basetsd;


// [SnakE 2009-02-23] Moved HANDLE definition here from winnt.d to avoid
// 'forwatd template reference' to CPtr from winnt.d caused by a circular
// import.
alias HANDLE = void*;

alias HANDLE* PHANDLE, LPHANDLE;

// helper for aligned structs
// alignVal 0 means the default align.
// _alignSpec as parameter does not pollute namespace.
package mixin template AlignedStr(int alignVal, string name, string memberlist,
                                    string _alignSpec = !alignVal ? "align" : "align("~alignVal.stringof~")" )
{
    mixin( _alignSpec ~ " struct " ~ name ~" { " ~ _alignSpec ~":"~ memberlist~" }" );
}

version (CoreUnittest) {
    private mixin AlignedStr!(16, "_Test_Aligned_Str", q{char a; char b;});
    private mixin AlignedStr!(0, "_Test_NoAligned_Str", q{char a; char b;});
}

version (Win64) {
    alias __int3264 = long;
enum ulong ADDRESS_TAG_BIT = 0x40000000000;

    alias long INT_PTR, LONG_PTR;
    alias long* PINT_PTR, PLONG_PTR;
    alias ulong UINT_PTR, ULONG_PTR, HANDLE_PTR;
    alias ulong* PUINT_PTR, PULONG_PTR;
    alias HALF_PTR = int;
    alias PHALF_PTR = int*;
    alias UHALF_PTR = uint;
    alias PUHALF_PTR = uint*;

    uint HandleToULong(void* h) { return(cast(uint) cast(ULONG_PTR) h); }
    int HandleToLong(void* h)   { return(cast(int) cast(LONG_PTR) h); }
    void* ULongToHandle(uint h) { return(cast(void*) cast(UINT_PTR) h); }
    void* LongToHandle(int h)   { return(cast(void*) cast(INT_PTR) h); }
    uint PtrToUlong(void* p)    { return(cast(uint) cast(ULONG_PTR) p); }
    uint PtrToUint(void* p)     { return(cast(uint) cast(UINT_PTR) p); }
    ushort PtrToUshort(void* p) { return(cast(ushort) cast(uint) cast(ULONG_PTR) p); }
    int PtrToLong(void* p)      { return(cast(int) cast(LONG_PTR) p); }
    int PtrToInt(void* p)       { return(cast(int) cast(INT_PTR) p); }
    short PtrToShort(void* p)   { return(cast(short) cast(int) cast(LONG_PTR) p); }
    void* IntToPtr(int i)       { return(cast(void*) cast(INT_PTR) i); }
    void* UIntToPtr(uint ui)    { return(cast(void*) cast(UINT_PTR) ui); }
    void* LongToPtr(int l)      { return(cast(void*) cast(LONG_PTR) l); }
    void* ULongToPtr(uint ul)   { return(cast(void*) cast(ULONG_PTR) ul); }

} else {
    alias __int3264 = int;
enum uint ADDRESS_TAG_BIT = 0x80000000;

    alias int INT_PTR, LONG_PTR;
    alias int* PINT_PTR, PLONG_PTR;
    alias uint UINT_PTR, ULONG_PTR, HANDLE_PTR;
    alias uint* PUINT_PTR, PULONG_PTR;
    alias HALF_PTR = short;
    alias PHALF_PTR = short*;
    alias UHALF_PTR = ushort;
    alias PUHALF_PTR = ushort*;

    uint HandleToUlong(HANDLE h)      { return cast(uint) h; }
    int HandleToLong(HANDLE h)        { return cast(int) h; }
    HANDLE LongToHandle(LONG_PTR h)   { return cast(HANDLE)h; }
    uint PtrToUlong(const(void)* p)    { return cast(uint) p; }
    uint PtrToUint(const(void)* p)     { return cast(uint) p; }
    int PtrToInt(const(void)* p)       { return cast(int) p; }
    ushort PtrToUshort(const(void)* p) { return cast(ushort) p; }
    short PtrToShort(const(void)* p)   { return cast(short) p; }
    void* IntToPtr(int i)             { return cast(void*) i; }
    void* UIntToPtr(uint ui)          { return cast(void*) ui; }
    alias LongToPtr = IntToPtr;
    alias ULongToPtr = UIntToPtr;
}

alias UIntToPtr UintToPtr, UlongToPtr;

enum : UINT_PTR {
    MAXUINT_PTR = UINT_PTR.max
}

enum : INT_PTR {
    MAXINT_PTR = INT_PTR.max,
    MININT_PTR = INT_PTR.min
}

enum : ULONG_PTR {
    MAXULONG_PTR = ULONG_PTR.max
}

enum : LONG_PTR {
    MAXLONG_PTR = LONG_PTR.max,
    MINLONG_PTR = LONG_PTR.min
}

enum : UHALF_PTR {
    MAXUHALF_PTR = UHALF_PTR.max
}

enum : HALF_PTR {
    MAXHALF_PTR = HALF_PTR.max,
    MINHALF_PTR = HALF_PTR.min
}

alias INT8 = byte;
alias PINT8 = byte*;
alias UINT8 = ubyte;
alias PUINT8 = ubyte*;

alias INT16 = short;
alias PINT16 = short*;
alias UINT16 = ushort;
alias PUINT16 = ushort*;

alias int LONG32, INT32;
alias int* PLONG32, PINT32;
alias uint ULONG32, DWORD32, UINT32;
alias uint* PULONG32, PDWORD32, PUINT32;

alias ULONG_PTR SIZE_T, DWORD_PTR;
alias ULONG_PTR* PSIZE_T, PDWORD_PTR;
alias SSIZE_T = LONG_PTR;
alias PSSIZE_T = LONG_PTR*;

alias long LONG64, INT64;
alias long* PLONG64, PINT64;
alias ulong ULONG64, DWORD64, UINT64;
alias ulong* PULONG64, PDWORD64, PUINT64;
