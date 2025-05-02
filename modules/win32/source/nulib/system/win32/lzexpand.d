/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_lzexpand.d)
 */
module nulib.system.win32.lzexpand;


version (ANSI) {} else version = Unicode;
pragma(lib, "lz32");

import nulib.system.win32.winbase, nulib.system.win32.windef;

enum : LONG {
    LZERROR_BADINHANDLE  = -1,
    LZERROR_BADOUTHANDLE = -2,
    LZERROR_READ         = -3,
    LZERROR_WRITE        = -4,
    LZERROR_GLOBALLOC    = -5,
    LZERROR_GLOBLOCK     = -6,
    LZERROR_BADVALUE     = -7,
    LZERROR_UNKNOWNALG   = -8
}

extern (Windows):
deprecated {
    LONG CopyLZFile(INT, INT);
    void LZDone();
    INT LZStart();
}
INT GetExpandedNameA(LPSTR, LPSTR);
INT GetExpandedNameW(LPWSTR, LPWSTR);
void LZClose(INT);
LONG LZCopy(INT, INT);
INT LZInit(INT);
INT LZOpenFileA(LPSTR, LPOFSTRUCT, WORD);
INT LZOpenFileW(LPWSTR, LPOFSTRUCT, WORD);
INT LZRead(INT, LPSTR, INT);
LONG LZSeek(INT, LONG, INT);

version (Unicode) {
    alias GetExpandedName = GetExpandedNameW;
    alias LZOpenFile = LZOpenFileW;
} else {
    alias GetExpandedName = GetExpandedNameA;
    alias LZOpenFile = LZOpenFileA;
}
