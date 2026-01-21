/**
    Adler32 Digest Algorithm
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
*/
module nulib.digest.adler;

/**
    Computes an adler32 checksum for the given buffer.

    Params:
        buffer =    The buffer to compute a checksum for
    
    Returns:
        The checksum of the given buffer
*/
uint adler32(ubyte[] buffer) @nogc nothrow {
    enum MOD_ADLER = 65521;

    uint a = 1;
    uint b = 0;
    foreach(byt; buffer) {
        a = (a + byt) % MOD_ADLER;
        b = (b + a) % MOD_ADLER;
    }

    return (b << 16) | a;
}

@("adler32: \"The quick brown fox jumps over the lazy dog\"")
unittest {
    string text = "The quick brown fox jumps over the lazy dog";
    assert(adler32(cast(ubyte[])text) == 0x5bdc0fda);  
}

@("adler32: \"Hello, world!\"")
unittest {
    string text = "Hello, world!";
    assert(adler32(cast(ubyte[])text) == 0x205e048a);  
}
