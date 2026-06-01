/**
    CRC Digest Algorithm
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
*/
module nulib.digest.crc;

/**
    A 32-bit CRC polynomial conforming to ISO 3309.

    Standard:
        The polynomial is defined in the ISO 3309 standard.
*/
enum uint CRC32_POLYNOMIAL_ISO = 0xedb88320;

/**
    A 64-bit CRC polynomial conforming to ECMA 182.

    Standard:
        The polynomial is defined in the ECMA 182 standard.
*/
enum ulong CRC64_POLYNOMIAL_ECMA = 0xC96C5795D7870F42;

/**
    A 64-bit CRC polynomial conforming to ISO 3309.

    Standard:
        The polynomial is defined in the ISO 3309 standard.
*/
enum ulong CRC64_POLYNOMIAL_ISO = 0xD800000000000000;

alias crc32 = crc!(uint, CRC32_POLYNOMIAL_ISO);
alias crc64_iso = crc!(ulong, CRC64_POLYNOMIAL_ISO);
alias crc64_ecma = crc!(ulong, CRC64_POLYNOMIAL_ECMA);

/**
    Generates a crc checksum from a buffer.

    Params:
        buffer =    The buffer to compute a checksum for
        crc =       The initial seed for the checksum.
    
    Returns:
        The checksum of the given buffer; checksums can be chained
        by passing the result to `crc` in a second iteration.
*/
T crc(T, T polynomial)(ubyte[] buffer, T crc = 0) @nogc nothrow
if (__traits(isIntegral, T) && __traits(isUnsigned, T)) {
    __gshared immutable(T)[256] __crc_table = _nu_gen_crc_table!T(polynomial);

    // Actual CRC algorithm.
    crc = ~crc;
    foreach(p; buffer) {
        crc = (crc >> 8) ^ __crc_table[(crc & 0xFF) ^ p];
    }
    return ~crc;
}


// Function which generates CRC tables
private immutable(T)[256] _nu_gen_crc_table(T)(T polynomial) {
    if (__ctfe) {
        T[256] result;
        T rem;
        foreach(i; 0..255) {
            rem = i;
            foreach(j; 0..8) {
                bool isRem1 = rem & 1;

                rem >>= 1;
                if (isRem1)
                    rem ^= polynomial;
            }
            result[i] = rem;
        }

        return result;
    } else {
        return typeof(return).init;
    }
}

@("crc32: \"The quick brown fox jumps over the lazy dog\"")
unittest {
    string text = "The quick brown fox jumps over the lazy dog";
    assert(crc32(cast(ubyte[])text) == 0x414fa339);  
}

@("crc32: \"Hello, world!\"")
unittest {
    string text = "Hello, world!";
    assert(crc32(cast(ubyte[])text) == 0xebe6c6e6);  
}

@("crc64_ecma: \"The quick brown fox jumps over the lazy dog\"")
unittest {
    string text = "The quick brown fox jumps over the lazy dog";
    assert(crc64_ecma(cast(ubyte[])text) == 0x5B5EB8C2E54AA1C4);  
}

@("crc64_ecma: \"Hello, world!\"")
unittest {
    string text = "Hello, world!";
    assert(crc64_ecma(cast(ubyte[])text) == 0x8E59E143665877C4);  
}

@("crc64_iso: \"The quick brown fox jumps over the lazy dog\"")
unittest {
    string text = "The quick brown fox jumps over the lazy dog";
    assert(crc64_iso(cast(ubyte[])text) == 0x4EF14E19F4C6E28E);  
}

@("crc64_iso: \"Hello, world!\"")
unittest {
    string text = "Hello, world!";
    assert(crc64_iso(cast(ubyte[])text) == 0xD176C45C2611D9C2);  
}