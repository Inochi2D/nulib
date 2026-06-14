/**
    NuLib INFLATE and DEFLATE support.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.compression.zlib;
version(Have_nulib_compression_z):
import nulib.compression.internal.z;
import numem.core.math;
import numem;

/**
    The size that inflate and deflate buffers grow by.
*/
enum Z_CHUNK_SIZE = 16_384;


/**
    Deflates the data in the given buffer to a newly allocated buffer.

    Params:
        data =  The data to compress
        level = The compression level to use, (0-12)
        flags = Flags to pass to the deflation algorithm

    Returns:
        The compressed data, or $(D null) on failure.
*/
ubyte[] deflate(T)(T[] data, uint level=6, int flags=TDEFL_WRITE_ZLIB_HEADER) @nogc nothrow {

    // Update flags.
    flags |= (((1U<<nu_min(12, level))-1)&TDEFL_MAX_PROBES_MASK);
    if (level == 0)
        flags |= TDEFL_FORCE_ALL_RAW_BLOCKS;

    // Compression loop.
    size_t ri = 0;
    size_t wi = 0;
    void[] inBuffer = cast(void[])data;
    ubyte[] outBuffer = nu_malloca!ubyte(Z_CHUNK_SIZE);
    do {
        size_t rc = nu_min(Z_CHUNK_SIZE, inBuffer.length-ri);

        if (size_t w = tdefl_compress_mem_to_mem(outBuffer.ptr+wi, Z_CHUNK_SIZE, inBuffer.ptr+ri, rc, flags)) {
            outBuffer = outBuffer.nu_resize(outBuffer.length+Z_CHUNK_SIZE);
            ri += rc;
            wi += w;
            continue;
        }

        // Failure.
        nu_freea(outBuffer);
        return null;
    } while(ri < inBuffer.length);

    return outBuffer[0..wi];
}

/**
    Inflates the data in the given buffer to a newly allocated buffer.

    Params:
        data =  The data to uncompress
        flags = Flags to pass to the algorithm.

    Returns:
        The uncompressed data, or $(D null) on failure.
*/
void[] inflate(ubyte[] data, int flags = TINFL_FLAG_PARSE_ZLIB_HEADER) @nogc nothrow {
    
    // Ensure user doesn't break the algorithm.
    flags &= ~TINFL_FLAG_HAS_MORE_INPUT; 

    // Compression loop.
    size_t ri = 0;
    size_t wi = 0;
    ubyte[] outBuffer = nu_malloca!ubyte(Z_CHUNK_SIZE);
    do {
        size_t rc = nu_min(Z_CHUNK_SIZE, data.length-ri);

        size_t w = tinfl_decompress_mem_to_mem(outBuffer.ptr+wi, Z_CHUNK_SIZE, data.ptr+ri, rc, flags | (ri < data.length ? TINFL_FLAG_HAS_MORE_INPUT : 0));
        if (w != TINFL_DECOMPRESS_MEM_TO_MEM_FAILED) {
            outBuffer = outBuffer.nu_resize(outBuffer.length+Z_CHUNK_SIZE);
            ri += rc;
            wi += w;
            continue;
        }

        // Failure.
        nu_freea(outBuffer);
        return null;
    } while(ri < data.length);

    return cast(void[])outBuffer[0..wi];
}

@("DEFLATE-INFLATE")
unittest {
    assert(inflate(deflate("Hello, world!")) == "Hello, world!");
}