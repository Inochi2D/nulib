/**
    Memory Streams

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.io.stream.memstream;
import nulib.io.stream;
import numem;

/**
    A stream over a memory buffer.

    MemoryStreams allow to write to a memory backed buffer,
    said buffer is owned by the memory stream and will grow
    to accomodate writes.

    Ownership can be taken from a memory stream using $(D take).

    Threadsafety:
        Memory streams are not thread safe objects; to share them
        between threads you must first finish your stream operations,
        then take ownership of the memory; you can then copy the result
        out of thread-local memory.
    
    Memory_safety:
        Generally, memory streams are safe to use as long as you do not
        mess with their ownership semantics; when passing an existing buffer
        to the memory stream, make sure that no other variable is referencing
        the backing buffer. The buffer's memory address may change during
        resize operations, which can lead to stale pointers outside of the
        memory stream.
    
    See_Also:
        $(D nulib.io.stream.rw.StreamReader), 
        $(D nulib.io.stream.rw.StreamWriter)
*/
class MemoryStream : Stream {
private:
@nogc nothrow @safe:
    ubyte[] buffer;
    size_t rptr;

public:

    /**
        Destructor.
    */
    ~this() @trusted {
        if (buffer.length != 0)
            buffer = nu_resize(buffer, 0, 1);
        
        rptr = 0;
    }

    /**
        Creates a new memory stream with $(D reserved) bytes of
        memory.
    
        Params:
            reserved = How many bytes to reserve.
    */
    this(size_t reserved) @trusted {
        buffer = nu_resize(buffer, reserved, 1);
    }

    /**
        Takes ownership of an existing buffer.
        
        Params:
            buffer =    The buffer to take ownership of,
                        the original buffer gets reset to its initial state. 
    */
    this(ref ubyte[] buffer) {
        this.buffer = buffer;
        buffer = null;
    }

    /**
        Whether the stream can be read from.

        Returns:
            $(D true) if you can read data from the stream,
            $(D false) otherwise.
    */
    override @property bool canRead() { return true; }

    /**
        Whether the stream can be written to.

        Returns:
            $(D true) if you can write data to the stream,
            $(D false) otherwise.
    */
    override @property bool canWrite() { return true; }
    
    /**
        Whether the stream can be seeked.

        Returns:
            $(D true) if you can seek through the stream,
            $(D false) otherwise.
    */
    override @property bool canSeek() { return true; }

    /**
        Whether the stream can timeout during operations.

        Returns:
            $(D true) if the stream may time out during operations,
            $(D false) otherwise.
    */
    override @property bool canTimeout() { return false; }

    /**
        Whether the stream can be flushed to disk.

        Returns:
            $(D true) if the stream may be flushed,
            $(D false) otherwise.
    */
    override @property bool canFlush() { return false; }

    /**
        Length of the stream.

        Returns:
            Length of the stream, or $(D -1) if the length is unknown.
    */
    override @property ptrdiff_t length() { return buffer.length; }

    /**
        Position in stream
    
        Returns
            Position in the stream, or $(D -1) if the position is unknown.
    */
    override @property ptrdiff_t tell() { return rptr; }

    /**
        Timeout in milliseconds before a read operation will fail.

        Returns
            A timeout in milliseconds, or $(D 0) if there's no timeout.
    */
    override @property int readTimeout() { return 0; }

    /**
        Timeout in milliseconds before a write operation will fail.

        Returns
            A timeout in milliseconds, or $(D 0) if there's no timeout.
    */
    override @property int writeTimeout() { return 0; }

    /**
        Clears all buffers of the stream and causes data to be written to the underlying device.
    
        Returns:
            $(D true) if the flush operation succeeded,
            $(D false) otherwise.
    */
    override bool flush() { return false; }

    /**
        Sets the reading position within the stream

        Returns
            The new position in the stream, or a $(D StreamError) if the 
            seek operation failed.
        
        See_Also:
            $(D StreamError)
    */
    override
    long seek(ptrdiff_t offset, SeekOrigin origin = SeekOrigin.start) {
        final switch(origin) {
            case SeekOrigin.start:
                ptrdiff_t newpos = cast(ptrdiff_t)offset;
                if (newpos > buffer.length || newpos < 0)
                    return STREAM_ERROR_OUT_OF_RANGE;
                
                rptr = newpos;
                return cast(long)rptr;
            case SeekOrigin.relative:
                ptrdiff_t newpos = cast(ptrdiff_t)rptr+offset;
                if (newpos > buffer.length || newpos < 0)
                    return STREAM_ERROR_OUT_OF_RANGE;
                    
                rptr = newpos;
                return cast(long)rptr;
            case SeekOrigin.end:
                ptrdiff_t newpos = cast(ptrdiff_t)buffer.length-offset;
                if (newpos > buffer.length || newpos < 0)
                    return STREAM_ERROR_OUT_OF_RANGE;

                rptr = newpos;
                return cast(long)rptr;
        }
    }

    /**
        Closes the stream.
    */
    override
    void close() @trusted {
        if (buffer)
            buffer = nu_resize(buffer, 0, 1);
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
    ptrdiff_t read(ubyte[] buffer) {
        ptrdiff_t start = rptr;
        ptrdiff_t end = rptr+buffer.length;

        // Snap to end
        if (end >= this.buffer.length)
            end = this.buffer.length;
        
        // EOF
        if (start == end)
            return STREAM_ERROR_EOF;
        
        // Read bytes into provided buffer
        rptr = end;
        buffer[0..end-start] = this.buffer[start..end];
        return end-start;
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
    ptrdiff_t write(ubyte[] buffer) @trusted {
        try {
            ptrdiff_t start = rptr;
            ptrdiff_t end = rptr+buffer.length;

            // Grow buffer
            this.buffer = nu_resize(this.buffer, end+1, 1);
            
            // Read bytes into the buffer
            rptr = end;
            this.buffer[start..end] = buffer[0..end-start];
            return end-start;
        } catch(Exception ex) {
            if (NuException nex = cast(NuException)ex)
                nex.free();
            
            return STREAM_ERROR_INVALID_STATE;
        }
    }

    /**
        Takes ownership of the memory in the memory stream,
        causing the memory stream to reset to its initial state.

        Returns:
            The slice that used to belong to the memory stream,
            the owner of the slice is responsible for freeing it.
    */
    final
    ubyte[] take() {
        ubyte[] result = buffer;

        buffer = null;
        rptr = 0;
        return result;
    }
}
