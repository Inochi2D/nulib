/**
    Windows API header module

    Translated from MinGW Windows headers

    License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors: Stewart Gordon, Luna Nielsen
*/
module nulib.system.win32.aclapi;
import nulib.system.win32.accctrl;
import nulib.system.win32.basetyps;
import nulib.system.win32.w32api;
import nulib.system.win32.winnt;

pragma(lib, "advapi32");

version (ANSI) {
} else version = Unicode;

extern (Windows) nothrow @nogc {
    VOID BuildExplicitAccessWithNameA(PEXPLICIT_ACCESS_A, LPSTR, DWORD,
        ACCESS_MODE, DWORD);
    VOID BuildExplicitAccessWithNameW(PEXPLICIT_ACCESS_W, LPWSTR, DWORD,
        ACCESS_MODE, DWORD);
    DWORD BuildSecurityDescriptorA(PTRUSTEE_A, PTRUSTEE_A, ULONG,
        PEXPLICIT_ACCESS_A, ULONG, PEXPLICIT_ACCESS_A, PSECURITY_DESCRIPTOR,
        PULONG, PSECURITY_DESCRIPTOR*);
    DWORD BuildSecurityDescriptorW(PTRUSTEE_W, PTRUSTEE_W, ULONG,
        PEXPLICIT_ACCESS_W, ULONG, PEXPLICIT_ACCESS_W, PSECURITY_DESCRIPTOR,
        PULONG, PSECURITY_DESCRIPTOR*);
    VOID BuildTrusteeWithNameA(PTRUSTEE_A, LPSTR);
    VOID BuildTrusteeWithNameW(PTRUSTEE_W, LPWSTR);
    VOID BuildTrusteeWithObjectsAndNameA(PTRUSTEE_A, POBJECTS_AND_NAME_A,
        SE_OBJECT_TYPE, LPSTR, LPSTR, LPSTR);
    VOID BuildTrusteeWithObjectsAndNameW(PTRUSTEE_W, POBJECTS_AND_NAME_W,
        SE_OBJECT_TYPE, LPWSTR, LPWSTR, LPWSTR);
    VOID BuildTrusteeWithObjectsAndSidA(PTRUSTEE_A, POBJECTS_AND_SID,
        GUID*, GUID*, PSID);
    VOID BuildTrusteeWithObjectsAndSidW(PTRUSTEE_W, POBJECTS_AND_SID,
        GUID*, GUID*, PSID);
    VOID BuildTrusteeWithSidA(PTRUSTEE_A, PSID);
    VOID BuildTrusteeWithSidW(PTRUSTEE_W, PSID);
    DWORD GetAuditedPermissionsFromAclA(PACL, PTRUSTEE_A, PACCESS_MASK,
        PACCESS_MASK);
    DWORD GetAuditedPermissionsFromAclW(PACL, PTRUSTEE_W, PACCESS_MASK,
        PACCESS_MASK);
    DWORD GetEffectiveRightsFromAclA(PACL, PTRUSTEE_A, PACCESS_MASK);
    DWORD GetEffectiveRightsFromAclW(PACL, PTRUSTEE_W, PACCESS_MASK);
    DWORD GetExplicitEntriesFromAclA(PACL, PULONG, PEXPLICIT_ACCESS_A*);
    DWORD GetExplicitEntriesFromAclW(PACL, PULONG, PEXPLICIT_ACCESS_W*);
    static if (_WIN32_WINNT >= 0x501) {
        DWORD GetInheritanceSourceA(LPSTR, SE_OBJECT_TYPE,
            SECURITY_INFORMATION, BOOL, GUID**, DWORD, PACL, void*,
            PGENERIC_MAPPING, PINHERITED_FROMA);
        DWORD GetInheritanceSourceW(LPWSTR, SE_OBJECT_TYPE,
            SECURITY_INFORMATION, BOOL, GUID**, DWORD, PACL, void*,
            PGENERIC_MAPPING, PINHERITED_FROMW);
    }
    DWORD GetNamedSecurityInfoA(LPSTR, SE_OBJECT_TYPE, SECURITY_INFORMATION,
        PSID*, PSID*, PACL*, PACL*, PSECURITY_DESCRIPTOR*);
    DWORD GetNamedSecurityInfoW(LPWSTR, SE_OBJECT_TYPE, SECURITY_INFORMATION,
        PSID*, PSID*, PACL*, PACL*, PSECURITY_DESCRIPTOR*);
    DWORD GetSecurityInfo(HANDLE, SE_OBJECT_TYPE, SECURITY_INFORMATION,
        PSID*, PSID*, PACL*, PACL*, PSECURITY_DESCRIPTOR*);
    TRUSTEE_FORM GetTrusteeFormA(PTRUSTEE_A);
    TRUSTEE_FORM GetTrusteeFormW(PTRUSTEE_W);
    LPSTR GetTrusteeNameA(PTRUSTEE_A);
    LPWSTR GetTrusteeNameW(PTRUSTEE_W);
    TRUSTEE_TYPE GetTrusteeTypeA(PTRUSTEE_A);
    TRUSTEE_TYPE GetTrusteeTypeW(PTRUSTEE_W);
    DWORD LookupSecurityDescriptorPartsA(PTRUSTEE_A*, PTRUSTEE_A*, PULONG,
        PEXPLICIT_ACCESS_A*, PULONG, PEXPLICIT_ACCESS_A*,
        PSECURITY_DESCRIPTOR);
    DWORD LookupSecurityDescriptorPartsW(PTRUSTEE_W*, PTRUSTEE_W*, PULONG,
        PEXPLICIT_ACCESS_W*, PULONG, PEXPLICIT_ACCESS_W*,
        PSECURITY_DESCRIPTOR);
    DWORD SetEntriesInAclA(ULONG, PEXPLICIT_ACCESS_A, PACL, PACL*);
    DWORD SetEntriesInAclW(ULONG, PEXPLICIT_ACCESS_W, PACL, PACL*);
    DWORD SetNamedSecurityInfoA(LPSTR, SE_OBJECT_TYPE, SECURITY_INFORMATION,
        PSID, PSID, PACL, PACL);
    DWORD SetNamedSecurityInfoW(LPWSTR, SE_OBJECT_TYPE, SECURITY_INFORMATION,
        PSID, PSID, PACL, PACL);
    DWORD SetSecurityInfo(HANDLE, SE_OBJECT_TYPE, SECURITY_INFORMATION, PSID,
        PSID, PACL, PACL);
    VOID BuildImpersonateExplicitAccessWithNameA(PEXPLICIT_ACCESS_A, LPSTR,
        PTRUSTEE_A, DWORD, ACCESS_MODE, DWORD);
    VOID BuildImpersonateExplicitAccessWithNameW(PEXPLICIT_ACCESS_W, LPWSTR,
        PTRUSTEE_W, DWORD, ACCESS_MODE, DWORD);
    VOID BuildImpersonateTrusteeA(PTRUSTEE_A, PTRUSTEE_A);
    VOID BuildImpersonateTrusteeW(PTRUSTEE_W, PTRUSTEE_W);
    PTRUSTEE_A GetMultipleTrusteeA(PTRUSTEE_A);
    PTRUSTEE_W GetMultipleTrusteeW(PTRUSTEE_W);
    MULTIPLE_TRUSTEE_OPERATION GetMultipleTrusteeOperationA(PTRUSTEE_A);
    MULTIPLE_TRUSTEE_OPERATION GetMultipleTrusteeOperationW(PTRUSTEE_W);
}

version (Unicode) {
    alias BuildExplicitAccessWithName = BuildExplicitAccessWithNameW;
    alias BuildSecurityDescriptor = BuildSecurityDescriptorW;
    alias BuildTrusteeWithName = BuildTrusteeWithNameW;
    alias BuildTrusteeWithObjectsAndName = BuildTrusteeWithObjectsAndNameW;
    alias BuildTrusteeWithObjectsAndSid = BuildTrusteeWithObjectsAndSidW;
    alias BuildTrusteeWithSid = BuildTrusteeWithSidW;
    alias GetAuditedPermissionsFromAcl = GetAuditedPermissionsFromAclW;
    alias GetEffectiveRightsFromAcl = GetEffectiveRightsFromAclW;
    alias GetExplicitEntriesFromAcl = GetExplicitEntriesFromAclW;
    alias GetNamedSecurityInfo = GetNamedSecurityInfoW;
    alias GetTrusteeForm = GetTrusteeFormW;
    alias GetTrusteeName = GetTrusteeNameW;
    alias GetTrusteeType = GetTrusteeTypeW;
    alias LookupSecurityDescriptorParts = LookupSecurityDescriptorPartsW;
    alias SetEntriesInAcl = SetEntriesInAclW;
    alias SetNamedSecurityInfo = SetNamedSecurityInfoW;
    alias BuildImpersonateExplicitAccessWithName = BuildImpersonateExplicitAccessWithNameW;
    alias BuildImpersonateTrustee = BuildImpersonateTrusteeW;
    alias GetMultipleTrustee = GetMultipleTrusteeW;
    alias GetMultipleTrusteeOperation = GetMultipleTrusteeOperationW;
} else {
    alias BuildExplicitAccessWithName = BuildExplicitAccessWithNameA;
    alias BuildSecurityDescriptor = BuildSecurityDescriptorA;
    alias BuildTrusteeWithName = BuildTrusteeWithNameA;
    alias BuildTrusteeWithObjectsAndName = BuildTrusteeWithObjectsAndNameA;
    alias BuildTrusteeWithObjectsAndSid = BuildTrusteeWithObjectsAndSidA;
    alias BuildTrusteeWithSid = BuildTrusteeWithSidA;
    alias GetAuditedPermissionsFromAcl = GetAuditedPermissionsFromAclA;
    alias GetEffectiveRightsFromAcl = GetEffectiveRightsFromAclA;
    alias GetExplicitEntriesFromAcl = GetExplicitEntriesFromAclA;
    alias GetNamedSecurityInfo = GetNamedSecurityInfoA;
    alias GetTrusteeForm = GetTrusteeFormA;
    alias GetTrusteeName = GetTrusteeNameA;
    alias GetTrusteeType = GetTrusteeTypeA;
    alias LookupSecurityDescriptorParts = LookupSecurityDescriptorPartsA;
    alias SetEntriesInAcl = SetEntriesInAclA;
    alias SetNamedSecurityInfo = SetNamedSecurityInfoA;
    alias BuildImpersonateExplicitAccessWithName = BuildImpersonateExplicitAccessWithNameA;
    alias BuildImpersonateTrustee = BuildImpersonateTrusteeA;
    alias GetMultipleTrustee = GetMultipleTrusteeA;
    alias GetMultipleTrusteeOperation = GetMultipleTrusteeOperationA;
}
