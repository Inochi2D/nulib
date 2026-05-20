module nulib.io.stream.file;
import nulib.io.stream;
import nulib.c.stdio;
import nulib.c.string;
import nulib.c.errno;
import nulib.math : min;
import nulib.string;
import numem;

/**
    Flags
*/
enum FileModeFlags {
    read    = 1,
    write   = 2,
    append  = 3,

    update  = 0x10,
    binary  = 0x20,
}

/**
    A file stream.
*/
class FileStream : Stream {
private:
@nogc @safe:
    FILE* handle;
    FileModeFlags flags;
    size_t fLength;

    void parseFileFlags(immutable(fchar_t)[] flags) nothrow {
        this.flags = cast(FileModeFlags)0;
        loop: foreach(i; 0..flags.length) {
            switch(flags[i]) {
                case 'r':
                    this.flags |= FileModeFlags.read;
                    break;
                case 'w':
                    this.flags |= FileModeFlags.write;
                    break;
                case 'a':
                    this.flags |= FileModeFlags.append;
                    break;
                case 'b':
                    this.flags |= FileModeFlags.binary;
                    break;
                case '+':
                    this.flags |= FileModeFlags.update;
                    break;
                default: break loop;
            }
        }
    }

    bool canUpdate() nothrow {
        return (flags & FileModeFlags.update) == FileModeFlags.update;
    }

    void updateLength() nothrow @trusted {
        if (!handle)
            return;
        
        if (canSeek) {
            this.seek(0, SeekOrigin.end);
            this.fLength = this.tell();
            this.seek(0, SeekOrigin.start);
        }
    }

public:

    /**
        Whether the stream can be read from.

        Returns:
            $(D true) if you can read data from the stream,
            $(D false) otherwise.
    */
    override @property bool canRead() nothrow {
        if (!handle)
            return false;
        
        if (this.canUpdate)
            return true;
        
        return (flags & FileModeFlags.read) != 0;
    }

    /**
        Whether the stream can be written to.

        Returns:
            $(D true) if you can write data to the stream,
            $(D false) otherwise.
    */
    override @property bool canWrite() nothrow {
        if (!handle)
            return false;
        
        if (this.canUpdate)
            return true;
        
        return (flags & FileModeFlags.write) != 0;
    }
    
    /**
        Whether the stream can be seeked.

        Returns:
            $(D true) if you can seek through the stream,
            $(D false) otherwise.
    */
    override @property bool canSeek() nothrow {
        if (!handle)
            return false;
        
        if (this.canUpdate)
            return true;
        
        return (flags & 3) > 0;
    }

    /**
        Whether the stream can timeout during operations.

        Returns:
            $(D true) if the stream may time out during operations,
            $(D false) otherwise.
    */
    override @property bool canTimeout() nothrow { return false; }

    /**
        Whether the stream can be flushed to disk.

        Returns:
            $(D true) if the stream may be flushed,
            $(D false) otherwise.
    */
    override @property bool canFlush() nothrow {
        if (!handle)
            return false;
        
        return (flags & 3) > 0;
    }

    /**
        Length of the stream.

        Returns:
            Length of the stream, or $(D -1) if the length is unknown.
    */
    override @property ptrdiff_t length() nothrow { 
        if (!handle)
            return -1;
        
        return fLength;
    }

    /**
        Position in stream
    
        Returns
            Position in the stream, or $(D -1) if the position is unknown.
    */
    override @property ptrdiff_t tell() nothrow @trusted {
        if (!handle)
            return -1;
        
        return ftell(handle);
    }

    /**
        Timeout in milliseconds before a read operation will fail.

        Returns
            A timeout in milliseconds, or $(D 0) if there's no timeout.
    */
    override @property int readTimeout() nothrow { return 0; }

    /**
        Timeout in milliseconds before a write operation will fail.

        Returns
            A timeout in milliseconds, or $(D 0) if there's no timeout.
    */
    override @property int writeTimeout() nothrow { return 0; }

    // Destructor
    ~this() nothrow @trusted {
        this.close();
    }

    /**
        Constructs a file stream.

        Params:
            path =  Path to the file to open
            mode =  Mode flags to open the file with.
    */
    this(string path, string mode) @trusted {
        auto rpath = path.toSupportedEncoding();
        auto rmode = mode.toSupportedEncoding();

        this.handle = _fopen(rpath.ptr, rmode.ptr);
        if(!handle) {
            this.flags = cast(FileModeFlags)0;

            nstring errMsg = strerror(errno);
            throw nogc_new!NuException(errMsg);
        }

        this.parseFileFlags(rmode);
        this.updateLength();
    }

    /**
        Clears all buffers of the stream and causes data to be written to the underlying device.
    
        Returns:
            $(D true) if the flush operation succeeded,
            $(D false) otherwise.
    */
    override bool flush() nothrow @trusted {
        if (!handle)
            return false;
        
        if (!canFlush)
            return false;
        
        return fflush(handle) == 0; 
    }

    /**
        Sets the reading position within the stream

        Returns
            The new position in the stream, or a $(D StreamError) if the 
            seek operation failed.
        
        See_Also:
            $(D StreamError)
    */
    override
    long seek(ptrdiff_t offset, SeekOrigin origin = SeekOrigin.start) nothrow @trusted {
        if (!handle)
            return StreamError.invalidState;
        
        if (!canSeek())
            return StreamError.notSupported;

        int status = fseek(handle, offset, origin);
        return status == 0 ? tell() : StreamError.outOfRange;
    }

    /**
        Closes the stream.
    */
    override
    void close() nothrow @trusted {
        if (handle) {
            cast(void)fclose(handle);
            this.handle = null;
        }
    }

    /**
        Reads bytes from the specified stream in to the specified buffer
        
        Notes:
            The position and length to read is specified by the slice of `buffer`.  
            Use slicing operation to specify a range to read to.

        Returns:
            The amount of bytes read from the stream, 
            or a $(D StreamError).
        
        See_Also:
            $(D StreamError)
    */
    override
    ptrdiff_t read(ubyte[] buffer) nothrow @trusted {
        if (!handle)
            return StreamError.invalidState;
        
        if (!this.canRead)
            return StreamError.notSupported;

        size_t rc = fread(cast(void*)buffer.ptr, 1, buffer.length, handle);
        return rc;
    }

    /**
        Writes bytes from the specified buffer in to the stream

        Notes
            The position and length to write is specified by the slice of `buffer`.  
            Use slicing operation to specify a range to write from.

        Returns:
            The amount of bytes read from the stream, 
            or a $(D StreamError).
        
        See_Also:
            $(D StreamError)
    */
    override
    ptrdiff_t write(ubyte[] buffer) nothrow @trusted {
        if (!handle)
            return StreamError.invalidState;
        
        if (!this.canWrite)
            return StreamError.notSupported;
        
        size_t rc = fwrite(cast(void*)buffer.ptr, 1, buffer.length, handle);
        return rc;
    }
}



//
//          IMPLEMENTATION DETAILS.
//

private:

StringImpl!(fchar_t) toSupportedEncoding(string str) @nogc {
    static if (is (fchar_t == char)) {
        return StringImpl!(fchar_t)(str);
    } else {
        import nulib.text.unicode : decode, encode;
        import numem.core.memory : nu_dup, nu_resize;

        auto tmp = str.nu_dup();
        auto rstr = encode!(StringImpl!(fchar_t))(decode(tmp), false);
        tmp = tmp.nu_resize(0);
        return rstr;
    }
}


version (CRuntime_Microsoft) 
    alias _fopen = _wfopen;
else
    alias _fopen = fopen;

version (CRuntime_Microsoft)
    alias fchar_t = wchar;
else
    alias fchar_t = char;
