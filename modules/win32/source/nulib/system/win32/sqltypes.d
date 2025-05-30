/**
$(RED Warning:
      This binding is out-of-date and does not allow use on non-Windows platforms. Use `etc.c.odbc.sqltypes` instead.)

 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_sqltypes.d)
 */

module nulib.system.win32.sqltypes;


version (ANSI) {} else version = Unicode;

/* Conversion notes:
  It's assumed that ODBC >= 0x0300.
*/

import nulib.system.win32.windef;
import nulib.system.win32.basetyps; // for GUID

alias byte SCHAR, SQLSCHAR;
alias int SDWORD, SLONG, SQLINTEGER;
alias short SWORD, SSHORT, RETCODE, SQLSMALLINT;
alias UDWORD = ULONG;
alias USHORT UWORD, SQLUSMALLINT;
alias double SDOUBLE, LDOUBLE;
alias SFLOAT = float;
alias PVOID PTR, HENV, HDBC, HSTMT, SQLPOINTER;
alias SQLCHAR = UCHAR;
// #ifndef _WIN64
alias SQLUINTEGER = UDWORD;
// #endif

//static if (ODBCVER >= 0x0300) {
alias SQLHANDLE = HANDLE;
alias SQLHANDLE SQLHENV, SQLHDBC, SQLHSTMT, SQLHDESC;
/*
} else {
alias SQLHENV = void*;
alias SQLHDBC = void*;
alias SQLHSTMT = void*;
}
*/
alias SQLRETURN = SQLSMALLINT;
alias SQLHWND = HWND;
alias BOOKMARK = ULONG;

alias SQLINTEGER SQLLEN, SQLROWOFFSET;
alias SQLUINTEGER SQLROWCOUNT, SQLULEN;
alias SQLTRANSID = DWORD;
alias SQLSETPOSIROW = SQLUSMALLINT;
alias SQLWCHAR = wchar;

version (Unicode) {
    alias SQLTCHAR = SQLWCHAR;
} else {
    alias SQLCHAR  SQLTCHAR;
}
//static if (ODBCVER >= 0x0300) {
alias ubyte  SQLDATE, SQLDECIMAL;
alias double SQLDOUBLE, SQLFLOAT;
alias ubyte  SQLNUMERIC;
alias float  SQLREAL;
alias ubyte  SQLTIME, SQLTIMESTAMP, SQLVARCHAR;
alias long   ODBCINT64, SQLBIGINT;
alias ulong  SQLUBIGINT;
//}

//Everything above this line may by used by odbcinst.d
//Everything below this line is deprecated
deprecated ("The ODBC 3.5 modules are deprecated. Please use the ODBC4 modules in the `etc.c.odbc` package."):

struct DATE_STRUCT {
    SQLSMALLINT year;
    SQLUSMALLINT month;
    SQLUSMALLINT day;
}

struct TIME_STRUCT {
    SQLUSMALLINT hour;
    SQLUSMALLINT minute;
    SQLUSMALLINT second;
}

struct TIMESTAMP_STRUCT {
    SQLSMALLINT year;
    SQLUSMALLINT month;
    SQLUSMALLINT day;
    SQLUSMALLINT hour;
    SQLUSMALLINT minute;
    SQLUSMALLINT second;
    SQLUINTEGER fraction;
}

//static if (ODBCVER >= 0x0300) {
alias SQL_DATE_STRUCT = DATE_STRUCT;
alias SQL_TIME_STRUCT = TIME_STRUCT;
alias SQL_TIMESTAMP_STRUCT = TIMESTAMP_STRUCT;

enum SQLINTERVAL {
    SQL_IS_YEAR = 1,
    SQL_IS_MONTH,
    SQL_IS_DAY,
    SQL_IS_HOUR,
    SQL_IS_MINUTE,
    SQL_IS_SECOND,
    SQL_IS_YEAR_TO_MONTH,
    SQL_IS_DAY_TO_HOUR,
    SQL_IS_DAY_TO_MINUTE,
    SQL_IS_DAY_TO_SECOND,
    SQL_IS_HOUR_TO_MINUTE,
    SQL_IS_HOUR_TO_SECOND,
    SQL_IS_MINUTE_TO_SECOND
}

struct SQL_YEAR_MONTH_STRUCT {
    SQLUINTEGER year;
    SQLUINTEGER month;
}

struct SQL_DAY_SECOND_STRUCT {
    SQLUINTEGER day;
    SQLUINTEGER hour;
    SQLUINTEGER minute;
    SQLUINTEGER second;
    SQLUINTEGER fraction;
}

struct SQL_INTERVAL_STRUCT {
    SQLINTERVAL interval_type;
    SQLSMALLINT interval_sign;
    union _intval {
        SQL_YEAR_MONTH_STRUCT year_month;
        SQL_DAY_SECOND_STRUCT day_second;
    }
    _intval intval;
}

enum SQL_MAX_NUMERIC_LEN = 16;

struct SQL_NUMERIC_STRUCT {
    SQLCHAR precision;
    SQLSCHAR scale;
    SQLCHAR sign;
    SQLCHAR[SQL_MAX_NUMERIC_LEN] val;
}
// } ODBCVER >= 0x0300
alias SQLGUID = GUID;
