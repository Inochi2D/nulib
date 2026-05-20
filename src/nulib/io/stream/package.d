/**
    Streams

    Base interface for Input/Output streams in nulib.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.io.stream;
import numem;

public import nulib.io.stream.memstream;

/**
    The origin of a seek operation
*/
enum SeekOrigin {

    /**
        Seek from beginning of stream
    */
    start = 0,

    /**
        Seek relative to the current position in the stream
    */
    relative = 1,

    /**
        Seek relative to the end of the stream
    */
    end = 2
}

/**
    Potential errors which can be raised by Stream R/W operations.

    Stream errors start from value $(D 0) which indicates an end-of-file
    event.
*/
enum StreamError : ptrdiff_t {
    
    /**
        End of file reached.
    */
    eof = 0,
    
    /**
        Operation is not supported by the stream.
    */
    notSupported = -1,
    
    /**
        Operation attempted to access out-of-range indices.
    */
    outOfRange = -2,

    /**
        Stream is in an invalid state; such as a file handle
        being closed.
    */
    invalidState = -3,
}

enum StreamError
    STREAM_ERROR_EOF = StreamError.eof,                     /// End of file reached.
    STREAM_ERROR_NOT_SUPPORTED = StreamError.notSupported,  /// Operation is not supported by the stream.
    STREAM_ERROR_OUT_OF_RANGE = StreamError.outOfRange,     /// Operation attempted to access out-of-range indices.
    STREAM_ERROR_INVALID_STATE = StreamError.invalidState;  /// Stream is in an invalid state.

/**
    A stream that can either be read from or written to.

    This is the base class of all stream related classes.

    Note:
        Stream objects should always be nothrow; use error
        codes as provided by $(D StreamError) to specify 
        failure states.
*/
abstract
class Stream : NuObject {
@nogc nothrow @safe:
public:

    /**
        Whether the stream can be read from.

        Returns:
            $(D true) if you can read data from the stream,
            $(D false) otherwise.
    */
    abstract @property bool canRead();

    /**
        Whether the stream can be written to.

        Returns:
            $(D true) if you can write data to the stream,
            $(D false) otherwise.
    */
    abstract @property bool canWrite();
    
    /**
        Whether the stream can be seeked.

        Returns:
            $(D true) if you can seek through the stream,
            $(D false) otherwise.
    */
    abstract @property bool canSeek();

    /**
        Whether the stream can timeout during operations.

        Returns:
            $(D true) if the stream may time out during operations,
            $(D false) otherwise.
    */
    abstract @property bool canTimeout();

    /**
        Whether the stream can be flushed to disk.

        Returns:
            $(D true) if the stream may be flushed,
            $(D false) otherwise.
    */
    abstract @property bool canFlush();

    /**
        Length of the stream.

        Returns:
            Length of the stream, or $(D -1) if the length is unknown.
    */
    abstract @property ptrdiff_t length();

    /**
        Position in stream
    
        Returns
            Position in the stream, or $(D -1) if the position is unknown.
    */
    abstract @property ptrdiff_t tell();

    /**
        Timeout in milliseconds before a read operation will fail.

        Returns
            A timeout in milliseconds, or $(D 0) if there's no timeout.
    */
    abstract @property int readTimeout();

    /**
        Timeout in milliseconds before a write operation will fail.

        Returns
            A timeout in milliseconds, or $(D 0) if there's no timeout.
    */
    abstract @property int writeTimeout();

    /**
        Clears all buffers of the stream and causes data to be written to the underlying device.
    
        Returns:
            $(D true) if the flush operation succeeded,
            $(D false) otherwise.
    */
    abstract bool flush();

    /**
        Sets the reading position within the stream

        Returns
            The new position in the stream, or a $(D StreamError) if the 
            seek operation failed.
        
        See_Also:
            $(D StreamError)
    */
    abstract long seek(ptrdiff_t offset, SeekOrigin origin = SeekOrigin.start);

    /**
        Closes the stream.
    */
    abstract void close();

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
    abstract ptrdiff_t read(ubyte[] buffer);

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
    abstract ptrdiff_t write(ubyte[] buffer);
}

/**
    An exception that can be thrown to indicate that a required operation
    is not supported by the given stream.

    Note:
        These exceptions are there for convenience for wrappers built
        on top of the base stream interface; such as stream readers/writers.
        The core functionality of streams will never throw.
*/
class StreamUnsupportedException : NuException {
@nogc:
public:

    /**
        The stream the exception applies to.
    */
    Stream stream;

    // Destructor.
    ~this() {

        // Ensure this doesn't end up getting freed.
        stream = null;
    }

    /**
        Constructor.
    */
    this(Stream stream, string file = __FILE__, size_t line = __LINE__) {
        this.stream = stream;

        super("The requested operation is not supported by the stream!", null, file, line);
    }
}

/**
    An exception that can be thrown to indicate that a read operation
    failed.

    Note:
        These exceptions are there for convenience for wrappers built
        on top of the base stream interface; such as stream readers/writers.
        The core functionality of streams will never throw.
*/
class StreamReadException : NuException {
@nogc:
public:

    /**
        The stream the exception applies to.
    */
    Stream stream;

    // Destructor.
    ~this() {

        // Ensure this doesn't end up getting freed.
        stream = null;
    }

    /**
        Constructor.
    */
    this(Stream stream, string reason, string file = __FILE__, size_t line = __LINE__) {
        this.stream = stream;

        super(reason, null, file, line);
    }
}

/**
    An exception that can be thrown to indicate that a write operation
    failed.

    Note:
        These exceptions are there for convenience for wrappers built
        on top of the base stream interface; such as stream readers/writers.
        The core functionality of streams will never throw.
*/
class StreamWriteException : NuException {
@nogc:
public:

    /**
        The stream the exception applies to.
    */
    Stream stream;

    // Destructor.
    ~this() {

        // Ensure this doesn't end up getting freed.
        stream = null;
    }

    /**
        Constructor.
    */
    this(Stream stream, string reason, string file = __FILE__, size_t line = __LINE__) {
        this.stream = stream;
        
        super(reason, null, file, line);
    }
}
