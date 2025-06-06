/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * Authors: Stewart Gordon
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_intshcut.d)
 */
module nulib.system.win32.intshcut;
import nulib.system.win32.windef;
import nulib.system.com;


version (ANSI) {} else version = Unicode;


enum : SCODE {
    E_FLAGS                     = 0x80041000,
      // = MAKE_SCODE(SEVERITY_ERROR, FACILITY_ITF, 0x1000)
    URL_E_INVALID_SYNTAX        = 0x80041001,
      // = MAKE_SCODE(SEVERITY_ERROR, FACILITY_ITF, 0x1001)
    URL_E_UNREGISTERED_PROTOCOL = 0x80041002, // etc.
    IS_E_EXEC_FAILED            = 0x80042002
}

enum IURL_SETURL_FLAGS {
    IURL_SETURL_FL_GUESS_PROTOCOL = 1,
    IURL_SETURL_FL_USE_DEFAULT_PROTOCOL,
    ALL_IURL_SETURL_FLAGS
}

enum IURL_INVOKECOMMAND_FLAGS {
    IURL_INVOKECOMMAND_FL_ALLOW_UI = 1,
    IURL_INVOKECOMMAND_FL_USE_DEFAULT_VERB,
    ALL_IURL_INVOKECOMMAND_FLAGS
}

enum TRANSLATEURL_IN_FLAGS {
    TRANSLATEURL_FL_GUESS_PROTOCOL = 1,
    TRANSLATEURL_FL_USE_DEFAULT_PROTOCOL,
    ALL_TRANSLATEURL_FLAGS
}

enum URLASSOCIATIONDIALOG_IN_FLAGS {
    URLASSOCDLG_FL_USE_DEFAULT_NAME = 1,
    URLASSOCDLG_FL_REGISTER_ASSOC,
    ALL_URLASSOCDLG_FLAGS
}

enum MIMEASSOCIATIONDIALOG_IN_FLAGS {
    MIMEASSOCDLG_FL_REGISTER_ASSOC = 1,
    ALL_MIMEASSOCDLG_FLAGS         = MIMEASSOCDLG_FL_REGISTER_ASSOC
}

struct URLINVOKECOMMANDINFO {
    DWORD dwcbSize = URLINVOKECOMMANDINFO.sizeof;
    DWORD dwFlags;
    HWND  hwndParent;
    PCSTR pcszVerb;
}
alias CURLINVOKECOMMANDINFO = URLINVOKECOMMANDINFO;
alias URLINVOKECOMMANDINFO* PURLINVOKECOMMANDINFO, PCURLINVOKECOMMANDINFO;

interface IUniformResourceLocator : IUnknown {
    HRESULT SetURL(PCSTR, DWORD);
    HRESULT GetURL(PSTR*);
    HRESULT InvokeCommand(PURLINVOKECOMMANDINFO);
}
//alias CIUniformResourceLocator = typeof(*(IUniformResourceLocator.init)); // value-type of interface not representable in D
alias IUniformResourceLocator PIUniformResourceLocator,
  PCIUniformResourceLocator;

extern (Windows) nothrow @nogc {
    BOOL InetIsOffline(DWORD);
    HRESULT MIMEAssociationDialogA(HWND, DWORD, PCSTR, PCSTR, PSTR, UINT);
    HRESULT MIMEAssociationDialogW(HWND, DWORD, PCWSTR, PCWSTR, PWSTR, UINT);
    HRESULT TranslateURLA(PCSTR, DWORD, PSTR*);
    HRESULT TranslateURLW(PCWSTR, DWORD, PWSTR*);
    HRESULT URLAssociationDialogA(HWND, DWORD, PCSTR, PCSTR, PSTR, UINT);
    HRESULT URLAssociationDialogW(HWND, DWORD, PCWSTR, PCWSTR, PWSTR, UINT);
}

version (Unicode) {
    alias TranslateURL = TranslateURLW;
    alias MIMEAssociationDialog = MIMEAssociationDialogW;
    alias URLAssociationDialog = URLAssociationDialogW;
} else {
    alias TranslateURL = TranslateURLA;
    alias MIMEAssociationDialog = MIMEAssociationDialogA;
    alias URLAssociationDialog = URLAssociationDialogA;
}
