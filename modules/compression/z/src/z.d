/**
    NuLib bindings to miniz

    Copyright:
        Copyright © 2013-2014, RAD Game Tools and Valve Software
        Copyright © 2010-2014, Rich Geldreich and Tenacious Software LLC
        Copyright © 2025, Kitsunebi Games EMV
    
    License:   $(LINK2 https://mit-license.org/, MIT License)
    Authors:   Luna Nielsen
*/
module nulib.compression.internal.z;
import miniz;
@nogc nothrow:



//
//          TDEFL
//

enum {
    TDEFL_HUFFMAN_ONLY = 0,
    TDEFL_DEFAULT_MAX_PROBES = 128,
    TDEFL_MAX_PROBES_MASK = 0xFFF
}

enum {
    
    /**
        If set, the compressor outputs a lib header before the deflate data, 
        and the Adler-32 of the source data at the end. 
        Otherwise, you'll get raw deflate data. 
    */
    TDEFL_WRITE_ZLIB_HEADER = 0x01000,
    
    /**
        Always compute the adler-32 of the  
        input data (even when not writing zlib headers). 
    */
    TDEFL_COMPUTE_ADLER32 = 0x02000,
    
    /**
        Set to use faster greedy parsing, instead of more efficient 
        lazy parsing. 
    */
    TDEFL_GREEDY_PARSING_FLAG = 0x04000,

    /**
        Enable to decrease the compressor's initialization time to the minimum, 
        but the output may vary from run to run given the same input 
        (depending on the contents of memory). 
    */
    TDEFL_NONDETERMINISTIC_PARSING_FLAG = 0x08000,
    
    /**
        Only look for RLE matches (matches with distance of 1) 
    */
    TDEFL_RLE_MATCHES = 0x10000,

    /**
        Discards matches <= 5 chars if enabled. 
    */
    TDEFL_FILTER_MATCHES = 0x20000,

    /**
        Disable usage of optimized Huffman tables.  
    */
    TDEFL_FORCE_ALL_STATIC_BLOCKS = 0x40000,
    
    /**
        Only use raw (uncompressed) deflate blocks. 
    */
    TDEFL_FORCE_ALL_RAW_BLOCKS = 0x80000
}

enum {
    TDEFL_STATUS_BAD_PARAM = -2,
    TDEFL_STATUS_PUT_BUF_FAILED = -1,
    TDEFL_STATUS_OKAY = 0,
    TDEFL_STATUS_DONE = 1
}

enum {
    TDEFL_NO_FLUSH = 0,
    TDEFL_SYNC_FLUSH = 2,
    TDEFL_FULL_FLUSH = 3,
    TDEFL_FINISH = 4
}

/**
    Compresses a block in memory to another block in memory.

    Params:
        pOutBuf =       Output buffer.
        outBufLen =     Length of output buffer, in bytes.
        pSrcBuf =       Source buffer.
        srcBufLen =     Length of source buffer, in bytes.
        flags =         Flags to pass to the decompression alogrithm

    Returns:
        The number of bytes written on success,
        $(D 0) otherwise.
*/
extern extern(C) size_t tdefl_compress_mem_to_mem(scope inout(void)* pOutBuf, size_t outBufLen, scope inout(void)* pSrcBuf, size_t srcBufLen, int flags);




//
//          TINFL
//

enum {

    /**
        If set, the input has a valid zlib header and ends with an adler32 
        checksum (it's a valid zlib stream). 
        Otherwise, the input is a raw deflate stream. 
    */
    TINFL_FLAG_PARSE_ZLIB_HEADER = 1,

    /**
        If set, there are more input bytes available beyond the end of the supplied input buffer. 
        If clear, the input buffer contains all remaining input. 
    */
    TINFL_FLAG_HAS_MORE_INPUT = 2,

    /**
        If set, the output buffer is large enough to hold the entire decompressed stream. 
        If clear, the output buffer is at least the size of the dictionary (typically 32KB). 
    */
    TINFL_FLAG_USING_NON_WRAPPING_OUTPUT_BUF = 4,

    /**
        Force adler-32 checksum computation of the decompressed bytes. 
    */
    TINFL_FLAG_COMPUTE_ADLER32 = 8
}

enum {
    /* This flags indicates the inflator needs 1 or more input bytes to make forward progress, but the caller is indicating that no more are available. The compressed data */
    /* is probably corrupted. If you call the inflator again with more bytes it'll try to continue processing the input but this is a BAD sign (either the data is corrupted or you called it incorrectly). */
    /* If you call it again with no input you'll just get TINFL_STATUS_FAILED_CANNOT_MAKE_PROGRESS again. */
    TINFL_STATUS_FAILED_CANNOT_MAKE_PROGRESS = -4,

    /* This flag indicates that one or more of the input parameters was obviously bogus. (You can try calling it again, but if you get this error the calling code is wrong.) */
    TINFL_STATUS_BAD_PARAM = -3,

    /* This flags indicate the inflator is finished but the adler32 check of the uncompressed data didn't match. If you call it again it'll return TINFL_STATUS_DONE. */
    TINFL_STATUS_ADLER32_MISMATCH = -2,

    /* This flags indicate the inflator has somehow failed (bad code, corrupted input, etc.). If you call it again without resetting via tinfl_init() it it'll just keep on returning the same status failure code. */
    TINFL_STATUS_FAILED = -1,

    /* Any status code less than TINFL_STATUS_DONE must indicate a failure. */

    /* This flag indicates the inflator has returned every byte of uncompressed data that it can, has consumed every byte that it needed, has successfully reached the end of the deflate stream, and */
    /* if zlib headers and adler32 checking enabled that it has successfully checked the uncompressed data's adler32. If you call it again you'll just get TINFL_STATUS_DONE over and over again. */
    TINFL_STATUS_DONE = 0,

    /* This flag indicates the inflator MUST have more input data (even 1 byte) before it can make any more forward progress, or you need to clear the TINFL_FLAG_HAS_MORE_INPUT */
    /* flag on the next call if you don't have any more source data. If the source data was somehow corrupted it's also possible (but unlikely) for the inflator to keep on demanding input to */
    /* proceed, so be sure to properly set the TINFL_FLAG_HAS_MORE_INPUT flag. */
    TINFL_STATUS_NEEDS_MORE_INPUT = 1,

    /* This flag indicates the inflator definitely has 1 or more bytes of uncompressed data available, but it cannot write this data into the output buffer. */
    /* Note if the source compressed data was corrupted it's possible for the inflator to return a lot of uncompressed data to the caller. I've been assuming you know how much uncompressed data to expect */
    /* (either exact or worst case) and will stop calling the inflator and fail after receiving too much. In pure streaming scenarios where you have no idea how many bytes to expect this may not be possible */
    /* so I may need to add some code to address this. */
    TINFL_STATUS_HAS_MORE_OUTPUT = 2
}

/**
    Flag denoting that decompression failed.    
*/
enum size_t TINFL_DECOMPRESS_MEM_TO_MEM_FAILED = cast(size_t)(-1);

/**
    Decompresses a block in memory to another block in memory.
    Params:
        pOutBuf =       Output buffer.
        outBufLen =     Length of output buffer, in bytes.
        pSrcBuf =       Source buffer.
        srcBufLen =     Length of source buffer, in bytes.
        flags =         Flags to pass to the decompression alogrithm

    Returns:
        The number of bytes written on success,
        $(D TINFL_DECOMPRESS_MEM_TO_MEM_FAILED) otherwise.
*/
extern extern(C) size_t tinfl_decompress_mem_to_mem(scope inout(void)* pOutBuf, size_t outBufLen, scope inout(void)* pSrcBuf, size_t srcBufLen, int flags);
