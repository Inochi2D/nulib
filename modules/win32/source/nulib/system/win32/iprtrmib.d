/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * Authors: Stewart Gordon
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_iprtrmib.d)
 */
module nulib.system.win32.iprtrmib;


import nulib.system.win32.ipifcons;
import nulib.system.win32.windef;

// FIXME: check types of constants

enum size_t
    MAXLEN_PHYSADDR        =   8,
    MAXLEN_IFDESCR         = 256,
    MAX_INTERFACE_NAME_LEN = 256;

enum {
    MIB_IPNET_TYPE_OTHER = 1,
    MIB_IPNET_TYPE_INVALID,
    MIB_IPNET_TYPE_DYNAMIC,
    MIB_IPNET_TYPE_STATIC
}

enum {
    MIB_TCP_RTO_OTHER = 1,
    MIB_TCP_RTO_CONSTANT,
    MIB_TCP_RTO_RSRE,
    MIB_TCP_RTO_VANJ
}

enum {
    MIB_TCP_STATE_CLOSED = 1,
    MIB_TCP_STATE_LISTEN,
    MIB_TCP_STATE_SYN_SENT,
    MIB_TCP_STATE_SYN_RCVD,
    MIB_TCP_STATE_ESTAB,
    MIB_TCP_STATE_FIN_WAIT1,
    MIB_TCP_STATE_FIN_WAIT2,
    MIB_TCP_STATE_CLOSE_WAIT,
    MIB_TCP_STATE_CLOSING,
    MIB_TCP_STATE_LAST_ACK,
    MIB_TCP_STATE_TIME_WAIT,
    MIB_TCP_STATE_DELETE_TCB // = 12
}

enum DWORD
    MIB_USE_CURRENT_TTL        = -1,
    MIB_USE_CURRENT_FORWARDING = -1,
    MIB_TCP_MAXCONN_DYNAMIC    = -1;

struct MIB_IPADDRROW {
    DWORD  dwAddr;
    DWORD  dwIndex;
    DWORD  dwMask;
    DWORD  dwBCastAddr;
    DWORD  dwReasmSize;
    ushort unused1;
    ushort unused2;
}
alias PMIB_IPADDRROW = MIB_IPADDRROW*;

struct MIB_IPADDRTABLE {
    DWORD            dwNumEntries;
    MIB_IPADDRROW[1] _table;

    MIB_IPADDRROW* table() return { return _table.ptr; }
}
alias PMIB_IPADDRTABLE = MIB_IPADDRTABLE*;

struct MIB_IPFORWARDROW {
    DWORD dwForwardDest;
    DWORD dwForwardMask;
    DWORD dwForwardPolicy;
    DWORD dwForwardNextHop;
    DWORD dwForwardIfIndex;
    DWORD dwForwardType;
    DWORD dwForwardProto;
    DWORD dwForwardAge;
    DWORD dwForwardNextHopAS;
    DWORD dwForwardMetric1;
    DWORD dwForwardMetric2;
    DWORD dwForwardMetric3;
    DWORD dwForwardMetric4;
    DWORD dwForwardMetric5;
}
alias PMIB_IPFORWARDROW = MIB_IPFORWARDROW*;

struct MIB_IPFORWARDTABLE {
    DWORD               dwNumEntries;
    MIB_IPFORWARDROW[1] _table;

    MIB_IPFORWARDROW* table() return { return _table.ptr; }
}
alias PMIB_IPFORWARDTABLE = MIB_IPFORWARDTABLE*;

struct MIB_IPNETROW {
    DWORD dwIndex;
    DWORD dwPhysAddrLen;
    BYTE[MAXLEN_PHYSADDR] bPhysAddr;
    DWORD dwAddr;
    DWORD dwType;
}
alias PMIB_IPNETROW = MIB_IPNETROW*;

struct MIB_IPNETTABLE {
    DWORD           dwNumEntries;
    MIB_IPNETROW[1] _table;

    MIB_IPNETROW* table() return { return _table.ptr; }
}
alias PMIB_IPNETTABLE = MIB_IPNETTABLE*;

struct MIBICMPSTATS {
    DWORD dwMsgs;
    DWORD dwErrors;
    DWORD dwDestUnreachs;
    DWORD dwTimeExcds;
    DWORD dwParmProbs;
    DWORD dwSrcQuenchs;
    DWORD dwRedirects;
    DWORD dwEchos;
    DWORD dwEchoReps;
    DWORD dwTimestamps;
    DWORD dwTimestampReps;
    DWORD dwAddrMasks;
    DWORD dwAddrMaskReps;
}
alias PMIBICMPSTATS = MIBICMPSTATS*;

struct MIBICMPINFO {
    MIBICMPSTATS icmpInStats;
    MIBICMPSTATS icmpOutStats;
}
alias PMIBICMPINFO = MIBICMPINFO*;

struct MIB_ICMP {
    MIBICMPINFO stats;
}
alias PMIB_ICMP = MIB_ICMP*;

struct MIB_IFROW {
    WCHAR[MAX_INTERFACE_NAME_LEN] wszName = 0;
    DWORD dwIndex;
    DWORD dwType;
    DWORD dwMtu;
    DWORD dwSpeed;
    DWORD dwPhysAddrLen;
    BYTE[MAXLEN_PHYSADDR] bPhysAddr;
    DWORD dwAdminStatus;
    DWORD dwOperStatus;
    DWORD dwLastChange;
    DWORD dwInOctets;
    DWORD dwInUcastPkts;
    DWORD dwInNUcastPkts;
    DWORD dwInDiscards;
    DWORD dwInErrors;
    DWORD dwInUnknownProtos;
    DWORD dwOutOctets;
    DWORD dwOutUcastPkts;
    DWORD dwOutNUcastPkts;
    DWORD dwOutDiscards;
    DWORD dwOutErrors;
    DWORD dwOutQLen;
    DWORD dwDescrLen;
    BYTE[MAXLEN_IFDESCR] bDescr;
}
alias PMIB_IFROW = MIB_IFROW*;

struct MIB_IFTABLE {
    DWORD        dwNumEntries;
    MIB_IFROW[1] _table;

    MIB_IFROW* table() return { return _table.ptr; }
}
alias PMIB_IFTABLE = MIB_IFTABLE*;

struct MIB_IPSTATS {
    DWORD dwForwarding;
    DWORD dwDefaultTTL;
    DWORD dwInReceives;
    DWORD dwInHdrErrors;
    DWORD dwInAddrErrors;
    DWORD dwForwDatagrams;
    DWORD dwInUnknownProtos;
    DWORD dwInDiscards;
    DWORD dwInDelivers;
    DWORD dwOutRequests;
    DWORD dwRoutingDiscards;
    DWORD dwOutDiscards;
    DWORD dwOutNoRoutes;
    DWORD dwReasmTimeout;
    DWORD dwReasmReqds;
    DWORD dwReasmOks;
    DWORD dwReasmFails;
    DWORD dwFragOks;
    DWORD dwFragFails;
    DWORD dwFragCreates;
    DWORD dwNumIf;
    DWORD dwNumAddr;
    DWORD dwNumRoutes;
}
alias PMIB_IPSTATS = MIB_IPSTATS*;

struct MIB_TCPSTATS {
    DWORD dwRtoAlgorithm;
    DWORD dwRtoMin;
    DWORD dwRtoMax;
    DWORD dwMaxConn;
    DWORD dwActiveOpens;
    DWORD dwPassiveOpens;
    DWORD dwAttemptFails;
    DWORD dwEstabResets;
    DWORD dwCurrEstab;
    DWORD dwInSegs;
    DWORD dwOutSegs;
    DWORD dwRetransSegs;
    DWORD dwInErrs;
    DWORD dwOutRsts;
    DWORD dwNumConns;
}
alias PMIB_TCPSTATS = MIB_TCPSTATS*;

struct MIB_TCPROW {
    DWORD dwState;
    DWORD dwLocalAddr;
    DWORD dwLocalPort;
    DWORD dwRemoteAddr;
    DWORD dwRemotePort;
}
alias PMIB_TCPROW = MIB_TCPROW*;

struct MIB_TCPTABLE {
    DWORD         dwNumEntries;
    MIB_TCPROW[1] _table;

    MIB_TCPROW* table() return { return _table.ptr; }
}
alias PMIB_TCPTABLE = MIB_TCPTABLE*;

struct MIB_UDPSTATS {
    DWORD dwInDatagrams;
    DWORD dwNoPorts;
    DWORD dwInErrors;
    DWORD dwOutDatagrams;
    DWORD dwNumAddrs;
}
alias PMIB_UDPSTATS = MIB_UDPSTATS*;

struct MIB_UDPROW {
    DWORD dwLocalAddr;
    DWORD dwLocalPort;
}
alias PMIB_UDPROW = MIB_UDPROW*;

struct MIB_UDPTABLE {
    DWORD         dwNumEntries;
    MIB_UDPROW[1] _table;

    MIB_UDPROW* table() return { return _table.ptr; }
}
alias PMIB_UDPTABLE = MIB_UDPTABLE*;
