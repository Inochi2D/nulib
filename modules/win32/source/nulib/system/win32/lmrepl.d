/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_lmrepl.d)
 */
module nulib.system.win32.lmrepl;

pragma(lib, "netapi32");

import nulib.system.win32.lmcons, nulib.system.win32.windef;

enum REPL_ROLE_EXPORT=1;
enum REPL_ROLE_IMPORT=2;
enum REPL_ROLE_BOTH=3;

enum REPL_INTERVAL_INFOLEVEL  = PARMNUM_BASE_INFOLEVEL+0;
enum REPL_PULSE_INFOLEVEL     = PARMNUM_BASE_INFOLEVEL+1;
enum REPL_GUARDTIME_INFOLEVEL = PARMNUM_BASE_INFOLEVEL+2;
enum REPL_RANDOM_INFOLEVEL    = PARMNUM_BASE_INFOLEVEL+3;

enum REPL_UNLOCK_NOFORCE=0;
enum REPL_UNLOCK_FORCE=1;
enum REPL_STATE_OK=0;
enum REPL_STATE_NO_MASTER=1;
enum REPL_STATE_NO_SYNC=2;
enum REPL_STATE_NEVER_REPLICATED=3;
enum REPL_INTEGRITY_FILE=1;
enum REPL_INTEGRITY_TREE=2;
enum REPL_EXTENT_FILE=1;
enum REPL_EXTENT_TREE=2;

enum REPL_EXPORT_INTEGRITY_INFOLEVEL = PARMNUM_BASE_INFOLEVEL+0;
enum REPL_EXPORT_EXTENT_INFOLEVEL    = PARMNUM_BASE_INFOLEVEL+1;

struct REPL_INFO_0 {
    DWORD rp0_role;
    LPWSTR rp0_exportpath;
    LPWSTR rp0_exportlist;
    LPWSTR rp0_importpath;
    LPWSTR rp0_importlist;
    LPWSTR rp0_logonusername;
    DWORD rp0_interval;
    DWORD rp0_pulse;
    DWORD rp0_guardtime;
    DWORD rp0_random;
}
alias REPL_INFO_0* PREPL_INFO_0, LPREPL_INFO_0;

struct REPL_INFO_1000 {
    DWORD rp1000_interval;
}
alias REPL_INFO_1000* PREPL_INFO_1000, LPREPL_INFO_1000;

struct REPL_INFO_1001 {
    DWORD rp1001_pulse;
}
alias REPL_INFO_1001* PREPL_INFO_1001, LPREPL_INFO_1001;

struct REPL_INFO_1002 {
    DWORD rp1002_guardtime;
}
alias REPL_INFO_1002* PREPL_INFO_1002, LPREPL_INFO_1002;

struct REPL_INFO_1003 {
    DWORD rp1003_random;
}
alias REPL_INFO_1003* PREPL_INFO_1003, LPREPL_INFO_1003;

struct REPL_EDIR_INFO_0 {
    LPWSTR rped0_dirname;
}
alias REPL_EDIR_INFO_0* PREPL_EDIR_INFO_0, LPREPL_EDIR_INFO_0;

struct REPL_EDIR_INFO_1 {
    LPWSTR rped1_dirname;
    DWORD rped1_integrity;
    DWORD rped1_extent;
}
alias REPL_EDIR_INFO_1* PREPL_EDIR_INFO_1, LPREPL_EDIR_INFO_1;

struct REPL_EDIR_INFO_2 {
    LPWSTR rped2_dirname;
    DWORD rped2_integrity;
    DWORD rped2_extent;
    DWORD rped2_lockcount;
    DWORD rped2_locktime;
}
alias REPL_EDIR_INFO_2* PREPL_EDIR_INFO_2, LPREPL_EDIR_INFO_2;

struct REPL_EDIR_INFO_1000 {
    DWORD rped1000_integrity;
}
alias REPL_EDIR_INFO_1000* PREPL_EDIR_INFO_1000, LPREPL_EDIR_INFO_1000;

struct REPL_EDIR_INFO_1001 {
    DWORD rped1001_extent;
}
alias REPL_EDIR_INFO_1001* PREPL_EDIR_INFO_1001, LPREPL_EDIR_INFO_1001;

struct REPL_IDIR_INFO_0 {
    LPWSTR rpid0_dirname;
}
alias REPL_IDIR_INFO_0* PREPL_IDIR_INFO_0, LPREPL_IDIR_INFO_0;

struct REPL_IDIR_INFO_1 {
    LPWSTR rpid1_dirname;
    DWORD rpid1_state;
    LPWSTR rpid1_mastername;
    DWORD rpid1_last_update_time;
    DWORD rpid1_lockcount;
    DWORD rpid1_locktime;
}
alias REPL_IDIR_INFO_1* PREPL_IDIR_INFO_1, LPREPL_IDIR_INFO_1;

extern (Windows) {
NET_API_STATUS NetReplGetInfo(LPCWSTR,DWORD,PBYTE*);
NET_API_STATUS NetReplSetInfo(LPCWSTR,DWORD,PBYTE,PDWORD);
NET_API_STATUS NetReplExportDirAdd(LPCWSTR,DWORD,PBYTE,PDWORD);
NET_API_STATUS NetReplExportDirDel(LPCWSTR,LPCWSTR);
NET_API_STATUS NetReplExportDirEnum(LPCWSTR,DWORD,PBYTE*,DWORD,PDWORD,PDWORD,PDWORD);
NET_API_STATUS NetReplExportDirGetInfo(LPCWSTR,LPCWSTR,DWORD,PBYTE*);
NET_API_STATUS NetReplExportDirSetInfo(LPCWSTR,LPCWSTR,DWORD,PBYTE,PDWORD);
NET_API_STATUS NetReplExportDirLock(LPCWSTR,LPCWSTR);
NET_API_STATUS NetReplExportDirUnlock(LPCWSTR,LPCWSTR,DWORD);
NET_API_STATUS NetReplImportDirAdd(LPCWSTR,DWORD,PBYTE,PDWORD);
NET_API_STATUS NetReplImportDirDel(LPCWSTR,LPCWSTR);
NET_API_STATUS NetReplImportDirEnum(LPCWSTR,DWORD,PBYTE*,DWORD,PDWORD,PDWORD,PDWORD);
NET_API_STATUS NetReplImportDirGetInfo(LPCWSTR,LPCWSTR,DWORD,PBYTE*);
NET_API_STATUS NetReplImportDirLock(LPCWSTR,LPCWSTR);
NET_API_STATUS NetReplImportDirUnlock(LPCWSTR,LPCWSTR,DWORD);
}
