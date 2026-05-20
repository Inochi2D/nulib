/**
    Stream Readers and Writers.

    Utility classes for reading from and writing to streams.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.io.stream.rw;
import nulib.io.stream;
import nulib.memory.endian;
import nulib.text.unicode;
import nulib.string;
import numem;

/**
    A stream reader is a helper class which makes it easier to
    read data from streams.
*/
final
class StreamReader : NuObject {
@nogc:
private:
    Stream stream_;

    // Reads a sequence of bytes and ensures their endianness is correct.
    // Additionally does a type-cast
    pragma(inline, true)
    T readEndian(T, Endianess endian)() @trusted if (__traits(isScalar, T)) {
        ubyte[T.sizeof] data;
        ptrdiff_t l = stream_.read(data);
        
        if (l <= 0)
            return T.init;
    
        return nu_etoh!(T, endian)(*(cast(T*)data.ptr));
    }

    // Reads a sequence of bytes and ensures their endianness is correct.
    pragma(inline, true)
    T[] readEndianSeq(T, Endianess endian)(size_t count) @trusted if (__traits(isScalar, T)) {
        T[] buffer;
        buffer = nu_resize(buffer, count, 1);
        ubyte[] bufferView = (cast(ubyte*)buffer.ptr)[0..count*T.sizeof];

        ptrdiff_t read = stream_.read(bufferView)/T.sizeof;
        return nu_etoh!(T, endian)(nu_resize(buffer, read <= 0 ? 0 : read, 1)[]);
    }

public:
@safe:

    /**
        The stream this reader is reading from
    */
    @property Stream stream() => stream_;

    /**
        Constructs a new stream reader
    */
    this(Stream stream) @trusted {
        enforce(stream.canRead(), nogc_new!StreamUnsupportedException(stream));
        this.stream_ = stream;
    }

    /**
        Reads a float from the stream.
        
        Returns:
            The read value.
    */
    float readF32LE() { return readEndian!(float, Endianess.littleEndian)(); }
    float readF32BE() { return readEndian!(float, Endianess.bigEndian)(); } /// ditto

    /**
        Reads a double from the stream.
        
        Returns:
            The read value.
    */
    double readF64LE() { return readEndian!(double, Endianess.littleEndian)(); }
    double readF64BE() { return readEndian!(double, Endianess.bigEndian)(); } /// ditto

    /**
        Reads a byte from the stream.
        
        Returns:
            The read value.
    */
    byte readI8() { return cast(byte)readU8(); }

    /**
        Reads a short from the stream.
        
        Returns:
            The read value.
    */
    short readI16LE() { return readEndian!(short, Endianess.littleEndian)(); }
    short readI16BE() { return readEndian!(short, Endianess.bigEndian)(); } /// ditto

    /**
        Reads a int from the stream.
        
        Returns:
            The read value.
    */
    int readI32LE() { return readEndian!(int, Endianess.littleEndian)(); }
    int readI32BE() { return readEndian!(int, Endianess.bigEndian)(); } /// ditto

    /**
        Reads a long from the stream.
        
        Returns:
            The read value.
    */
    long readI64LE() { return readEndian!(long, Endianess.littleEndian)(); }
    long readI64BE() { return readEndian!(long, Endianess.bigEndian)(); } /// ditto

    /**
        Reads a ubyte from the stream.
        
        Returns:
            The read value.
    */
    ubyte readU8() {
        ubyte[1] buffer;
        stream.read(buffer);
        return buffer[0];
    }

    /**
        Reads a ushort from the stream.
        
        Returns:
            The read value.
    */
    ushort readU16LE() { return readEndian!(ushort, Endianess.littleEndian)(); }
    ushort readU16BE() { return readEndian!(ushort, Endianess.bigEndian)(); } /// ditto

    /**
        Reads a uint from the stream.
        
        Returns:
            The read value.
    */
    uint readU32LE() { return readEndian!(uint, Endianess.littleEndian)(); }
    uint readU32BE() { return readEndian!(uint, Endianess.bigEndian)(); } /// ditto

    /**
        Reads a ulong from the stream.
        
        Returns:
            The read value.
    */
    ulong readU64LE() { return readEndian!(ulong, Endianess.littleEndian)(); }
    ulong readU64BE() { return readEndian!(ulong, Endianess.bigEndian)(); } /// ditto

    /**
        Reads a value from the stream.
        
        Returns:
            The read value.
    */
    T readLE(T)() { return readEndian!(T, Endianess.littleEndian)(); }
    T readBE(T)() { return readEndian!(T, Endianess.bigEndian)(); }

    /**
        Reads a UTF8 string from the stream.
        
        Returns:
            The UTF8 string read from the stream.
    */
    nstring readUTF8(uint length) @trusted {
        char[] buffer = nu_malloca!char(length);
        ptrdiff_t read = stream.read(cast(ubyte[])buffer);
        
        nstring result = nstring(buffer[0..read]);
        nu_freea(buffer);
        return result;
    }

    /**
        Reads a UTF16 string from the stream.

        This function determines endianness from the byte-order-mark
        in the stream; if none is found an exception is thrown.

        Params:
            length = the length of the string to read, including BOM.
        
        Returns:
            The UTF16 string read from the stream.
    */
    nwstring readUTF16(uint length) @trusted {
        wchar[] buffer = this.readEndianSeq!(wchar, NATIVE_ENDIAN)(length);
        codepoint bom = getBOM(buffer);

        if (!bom) {
            
            // Clear buffer.
            buffer = nu_resize(buffer, 0, 1);
            throw nogc_new!StreamReadException(stream, "UTF16 string did not have a BOM!");
        }

        // Copy UTF-16 string out.
        nwstring out_ = nwstring(nu_etoh!wchar(buffer, getEndianFromBOM(bom)));
        nu_freea(buffer);
        return out_;
    }

    /**
        Reads a UTF16 string from the stream.

        Params:
            length = the length of the string to read, including BOM, if any.
        
        Returns:
            The UTF16 string read from the stream.
    */
    nwstring readUTF16LE(uint length) @trusted {
        wchar[] buffer = this.readEndianSeq!(wchar, Endianess.littleEndian)(length);
        nwstring out_ = nwstring(buffer);
        nu_freea(buffer);
        return out_;
    }

    /**
        Reads a UTF16 string from the stream.

        Params:
            length = the length of the string to read, including BOM, if any.
        
        Returns:
            The UTF16 string read from the stream.
    */
    nwstring readUTF16BE(uint length) @trusted {
        wchar[] buffer = this.readEndianSeq!(wchar, Endianess.bigEndian)(length);
        nwstring out_ = nwstring(buffer);
        nu_freea(buffer);
        return out_;
    }

    /**
        Reads a UTF32 string from the stream.

        This function determines endianness from the byte-order-mark
        in the stream; if none is found an exception is thrown.

        Params:
            length = the length of the string to read, including BOM.
        
        Returns:
            The UTF32 string read from the stream.
    */
    ndstring readUTF32(uint length) @trusted {
        dchar[] buffer = this.readEndianSeq!(dchar, NATIVE_ENDIAN)(length);
        codepoint bom = getBOM(buffer);

        if (!bom) {
            
            // Clear buffer.
            buffer = nu_resize(buffer, 0, 1);
            throw nogc_new!StreamReadException(stream, "UTF32 string did not have a BOM!");
        }

        // Copy UTF-16 string out.
        ndstring out_ = ndstring(nu_etoh!dchar(buffer, getEndianFromBOM(bom)));
        nu_freea(buffer);
        return out_;
    }

    /**
        Reads a UTF32 string from the stream.

        Params:
            length = the length of the string to read, including BOM, if any.
        
        Returns:
            The UTF32 string read from the stream.
    */
    ndstring readUTF32LE(uint length) @trusted {
        dchar[] buffer = this.readEndianSeq!(dchar, Endianess.littleEndian)(length);
        ndstring out_ = ndstring(buffer);
        nu_freea(buffer);
        return out_;
    }

    /**
        Reads a UTF32 string from the stream.

        Params:
            length = the length of the string to read, including BOM, if any.
        
        Returns:
            The UTF32 string read from the stream.
    */
    ndstring readUTF32BE(uint length) @trusted {
        dchar[] buffer = this.readEndianSeq!(dchar, Endianess.bigEndian)(length);
        ndstring out_ = ndstring(buffer);
        buffer = nu_resize(buffer, 0, 1);
        return out_;
    }
}

/**
    A stream writer is a helper class which makes it easier to
    write data to streams.
*/
final
class StreamWriter : NuObject {
@nogc:
private:
    Stream stream_;

    // Reads a sequence of bytes and ensures their endianness is correct.
    // Additionally does a type-cast
    pragma(inline, true)
    void writeEndian(Endianess endian, T)(T value) @trusted if (__traits(isScalar, T)) {
        import numem.core.traits : Unqual;
        alias UT = Unqual!T;

        value = cast(T)nu_etoh!(T, endian)(cast(UT)value);
        ubyte[] bufferView = (cast(ubyte*)&value)[0..T.sizeof];
        stream.write(bufferView);
    }

    // Reads a sequence of bytes and ensures their endianness is correct.
    pragma(inline, true)
    void writeEndianSeq(Endianess endian, T)(T[] values) @trusted if (__traits(isScalar, T)) {
        import numem.core.traits : Unqual;
        alias UT = Unqual!(T[]);

        auto buffer = cast(ubyte[])cast(void[])nu_etoh!(UT, endian)(cast(UT)values.nu_dup());
        stream.write(buffer);
        nu_freea(buffer);
    }

public:
@safe:

    /**
        The stream this writer is writing to
    */
    @property Stream stream() => stream_;

    /**
        Constructs a new stream writer
    */
    this(Stream stream) @trusted{
        enforce(stream.canWrite(), nogc_new!StreamUnsupportedException(stream));
        this.stream_ = stream;
    }

    /**
        Reads a value from the stream.
        
        Returns:
            The read value.
    */
    void writeLE(T)(T value) { writeEndian!(Endianess.littleEndian)(value); }
    void writeBE(T)(T value) { writeEndian!(Endianess.littleEndian)(value); }

    /**
        Writes a UTF8 string to the stream.

        Params:
            value = The string to write to the stream.
    */
    void writeUTF8(string value) @trusted {
        stream.write(cast(ubyte[])value);
    }

    /**
        Writes a UTF16 string to the stream.

        Params:
            value = The string to write to the stream.
    */
    void writeUTF16(wstring value) @trusted {
        stream.write(cast(ubyte[])cast(void[])value);
    }

    /**
        Writes a UTF16 string to the stream.

        Params:
            value = The string to write to the stream.
    */
    void writeUTF16LE(wstring value) @trusted {
        this.writeEndianSeq!(Endianess.littleEndian)(value);
    }

    /**
        Writes a UTF16 string to the stream.

        Params:
            value = The string to write to the stream.
    */
    void writeUTF16BE(wstring value) @trusted {
        this.writeEndianSeq!(Endianess.bigEndian)(value);
    }

    /**
        Writes a UTF32 string to the stream.

        Params:
            value = The string to write to the stream.
    */
    void writeUTF32(dstring value) @trusted {
        stream.write(cast(ubyte[])cast(void[])value);
    }

    /**
        Writes a UTF32 string to the stream.

        Params:
            value = The string to write to the stream.
    */
    void writeUTF32LE(dstring value) @trusted {
        this.writeEndianSeq!(Endianess.littleEndian)(value);
    }

    /**
        Writes a UTF32 string to the stream.

        Params:
            value = The string to write to the stream.
    */
    void writeUTF32BE(dstring value) @trusted {
        this.writeEndianSeq!(Endianess.bigEndian)(value);
    }
}
