/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * Authors: Stewart Gordon
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_errorrep.d)
 */
module nulib.system.win32.errorrep;


version (ANSI) {} else version = Unicode;

import nulib.system.win32.w32api, nulib.system.win32.windef;

static assert (_WIN32_WINNT >= 0x501,
    "nulib.system.win32.errorrep is available only if version WindowsXP, Windows2003 "
    ~ "or WindowsVista is set");

enum EFaultRepRetVal {
    frrvOk,
    frrvOkManifest,
    frrvOkQueued,
    frrvErr,
    frrvErrNoDW,
    frrvErrTimeout,
    frrvLaunchDebugger,
    frrvOkHeadless // = 7
}

extern (Windows) nothrow @nogc {
    BOOL AddERExcludedApplicationA(LPCSTR);
    BOOL AddERExcludedApplicationW(LPCWSTR);
    EFaultRepRetVal ReportFault(LPEXCEPTION_POINTERS, DWORD);
}

version (Unicode) {
    alias AddERExcludedApplication = AddERExcludedApplicationW;
} else {
    alias AddERExcludedApplication = AddERExcludedApplicationA;
}
