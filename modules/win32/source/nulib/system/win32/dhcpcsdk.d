/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * Authors: Stewart Gordon
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_dhcpcsdk.d)
 */
module nulib.system.win32.dhcpcsdk;


import nulib.system.win32.w32api, nulib.system.win32.windef;

/*static assert (_WIN32_WINNT >= 0x500,
"nulib.system.win32.dhcpcsdk is available only if version Windows2000, WindowsXP, Windows2003
or WindowsVista is set");*/

//#if (_WIN32_WINNT >= 0x500)

// FIXME: check type
enum DHCPCAPI_REGISTER_HANDLE_EVENT = 1;
enum DHCPCAPI_REQUEST_PERSISTENT    = 1;
enum DHCPCAPI_REQUEST_SYNCHRONOUS   = 2;

struct DHCPCAPI_CLASSID {
    ULONG  Flags;
    LPBYTE Data;
    ULONG  nBytesData;
}
alias DHCPCAPI_CLASSID* PDHCPCAPI_CLASSID, LPDHCPCAPI_CLASSID;

struct DHCPAPI_PARAMS {
    ULONG  Flags;
    ULONG  OptionId;
    BOOL   IsVendor;
    LPBYTE Data;
    DWORD  nBytesData;
}
alias DHCPAPI_PARAMS* PDHCPAPI_PARAMS, LPDHCPAPI_PARAMS;

struct DHCPCAPI_PARAMS_ARRAY {
    ULONG            nParams;
    LPDHCPAPI_PARAMS Params;
}
alias DHCPCAPI_PARAMS_ARRAY* PDHCPCAPI_PARAMS_ARRAY, LPDHCPCAPI_PARAMS_ARRAY;

extern (Windows) nothrow @nogc {
    void DhcpCApiCleanup();
    DWORD DhcpCApiInitialize(LPDWORD);
    DWORD DhcpDeRegisterParamChange(DWORD, LPVOID, LPVOID);
    DWORD DhcpRegisterParamChange(DWORD, LPVOID, PWSTR, LPDHCPCAPI_CLASSID,
      DHCPCAPI_PARAMS_ARRAY, LPVOID);
    DWORD DhcpRemoveDNSRegistrations();
    DWORD DhcpUndoRequestParams(DWORD, LPVOID, LPWSTR, LPWSTR);
}

//#endif // (_WIN32_WINNT >= 0x500)
