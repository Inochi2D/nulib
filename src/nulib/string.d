/**
    nogc strings

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.string;
import numem.core.hooks;
import numem.core.traits;
import numem.core.memory;
import numem.core.meta;
import numem;
import nulib.collections.internal.marray;
import nulib.text.unicode : 
    encode, 
    decode;

//
//              STRING TRAITS
//




/// Gets whether the provided type is some type of string.
enum isSomeString(T) =
    isSomeSafeString!T ||
    isSomeCString!T;

/**
    Gets whether the provided type is some type of string
    which is length denoted and therefore "safe"
*/
enum isSomeSafeString(T) =
    isSomeNString!T ||
    isSomeDString!T;


/// Gets whether the provided type is some type of nstring.
enum isSomeNString(T) = 
    is(inout(T) == inout(StringImpl!C), C) && isSomeChar!C;

/// Gets whether the provided type is some type of null terminated C string.
enum isSomeCString(T) =
    is(T == C*, C) && isSomeChar!C;

/// Gets whether the provided type is some type of D string slice.
enum isSomeDString(T) =
    (is(immutable(T) == immutable(C[]), C) && isSomeChar!C) ||
    (is(T : C2[], C2) && isSomeChar!C2);

/// Gets whether the provided type is a character
enum isSomeChar(T) =
    is(T : char) || is(T : wchar) || is(T : dchar);

/**
    Gets whether $(D T) is convertible to any form of $(D nstring)
*/
enum isStringable(T) = 
    __traits(hasMember, T, "toString") &&
    isSomeString!(ReturnType!(T.toString));

/**
    Gets the size of the element in a string-ish type in bytes.
*/
enum StringCharSize(T) =
    StringCharType!T.sizeof;

/**
    Gets the type of the element in a string-ish type.
*/
template StringCharType(T) {
    static if (isSomeString!T) {
        static if(isSomeNString!T)
            alias StringCharType = Unqual!(T.CharType);
        else
            alias StringCharType = Unqual!(typeof(T.init[0].init));
    } else {
        alias StringCharType = void;
    }
}


//
//              NSTRING ALIASES
//

/**
    A @nogc UTF-8 string

    Note:
        $(D nstring) is passed $(B by value), this effectively means
        that if you do not pass it as $(D ref) you will end up copying
        the contents of the string.
    
    See_Also:
        $(D nwstring)
        $(D ndstring)
*/
alias nstring = StringImpl!(char);

/**
    A @nogc UTF-16 string

    Note:
        $(D nwstring) is passed $(B by value), this effectively means
        that if you do not pass it as $(D ref) you will end up copying
        the contents of the string.
    
    See_Also:
        $(D nstring)
        $(D ndstring)
*/
alias nwstring = StringImpl!(wchar);

/**
    A @nogc UTF-32 string

    Note:
        $(D ndstring) is passed $(B by value), this effectively means
        that if you do not pass it as $(D ref) you will end up copying
        the contents of the string.
    
    See_Also:
        $(D nstring)
        $(D nwstring)
*/
alias ndstring = StringImpl!(dchar);


//
//          STRING IMPLEMENTATION.
//



/**
    The underlying implementation of a numem string.
*/
struct StringImpl(T) if (isSomeChar!T) {
@nogc:
private:
    alias SelfType = typeof(this);
    alias MemoryT = immutable(T)[];
    
    // Backing slice of the string.
    immutable(T)[] memory = null;
    size_t flags;

    /**
        Flag which indicates that the string is read-only.
    */
    enum size_t STRFLAG_READONLY = 0x01;

    // Resizing algorithm
    pragma(inline, true)
    void resizeImpl(size_t newLength) @trusted {
        if (flags & STRFLAG_READONLY)
            this.takeOwnershipImpl();

        if (newLength == 0) {
            if (memory.ptr !is null)
                memory.nu_resize(0);
            
            nogc_zeroinit(memory);
            return;
        }

        // NOTE: nu_terminatd re-allocates the slice twice,
        // As such we put a smaller implementation here.
        memory = memory.nu_resize(newLength+1);
        (cast(T*)memory.ptr)[newLength] = '\0';
        memory = memory[0..$-1];
    }

    // Range set algorithm
    pragma(inline, true)
    void setRangeImpl(inout(T)[] dst, inout(T)[] src) {
        if (memory)
            nu_memmove(cast(void*)dst.ptr, cast(void*)src.ptr, src.length*T.sizeof);
    }

    // Char set algorithm
    pragma(inline, true)
    void setCharImpl(void* at, T c) {
        if (memory)
            *(cast(T*)at) = c;
    }

    // Takes ownership of string.
    pragma(inline, true)
    void takeOwnershipImpl() {
        if (flags & STRFLAG_READONLY) {
            this.memory = memory.nu_idup();
            this.flags &= ~STRFLAG_READONLY;
        }
    }

    // Resets the string.
    pragma(inline, true)
    void resetImpl() {
        this.memory = null;
        this.flags = 0;
    }

    // Makes a copy of the given string transformed
    // to fit the encoding of this string.
    pragma(inline, true)
    MemoryT otherToSelf(U)(auto ref U in_) 
    if(isSomeString!U) {
        static if (is(StringCharType!SelfType == StringCharType!U)) {
            auto val = in_.sliceof.nu_dup();
            return val.nu_terminate();
        } else {

            // Otherwise we need to do unicode conversion.
            auto dec = decode(in_.sliceof, false);
            auto enc = encode!SelfType(dec, false);
            return enc.take();
        }
    }

public:
    alias value this;

    /**
        The type of character the string contains.
    */
    alias CharType = T;

    /**
        The length of the string.
    */
    @property size_t length() @safe nothrow { return memory.length; }

    /**
        Gets the length of the string, with the null terminator.
    */
    @property size_t realLength() @safe nothrow { return memory.ptr ? memory.length+1 : 0; }
    
    /**
        The length of the string, in bytes.
    */
    @property size_t usage() @safe nothrow { return memory.length*T.sizeof; }

    /**
        Whether the string is empty.
    */
    @property bool empty() @safe nothrow { return memory.length == 0; }

    /**
        Gets a C string pointer to the nstring.
    */
    @property const(T)* ptr() @system nothrow { return cast(const(T)*)memory.ptr; }

    /**
        Gets the internal memory slice.
    */
    @property immutable(T)[] value() inout @trusted nothrow pure { return memory; }

    // Aliases for legacy purposes.
    alias toDString = value;
    alias toCString = ptr;

    ~this() {
        this.resizeImpl(0);
    }

    /**
        Creates a string from a string from any other UTF encoding.
    */
    this(U)(auto ref U rhs) @system
    if (isSomeString!U) {
        if (__ctfe) {
            static if (is(StringCharType!U == StringCharType!SelfType)) {
                this.flags |= STRFLAG_READONLY;
                this.memory = cast(MemoryT)rhs.sliceof;
            }
        } else {
            if (rhs) {
                static if (is(StringCharType!U == StringCharType!SelfType)) {
                    this.memory = cast(MemoryT)rhs.sliceof.nu_dup();
                    nu_terminate(memory);
                } else {
                    auto val = otherToSelf(rhs.sliceof);
                    this.memory = val;
                }
            } else {
                nogc_zeroinit(this.memory);
            }
        }
    }

    this(Args...)(auto ref Args args) @system
    if(allSatisfy!(.isSomeString, Args)) {
        if (__ctfe) {
            this.flags |= STRFLAG_READONLY;
            foreach(arg; args)
                this.memory ~= cast(MemoryT)arg.sliceof;
            this.memory ~= "\0";
            
        } else {

            // Get combined length of strings.
            size_t sz = 0;
            static foreach(arg; args) {
                sz += arg.sliceof.length;
            }

            // Allocate new string
            char[] buffer = nu_malloca!T(sz);
            size_t i; // Write offset
            MemoryT tmp;
            static foreach(arg; args) {
                tmp = otherToSelf(arg.sliceof);
                buffer[i..i+tmp.length] = tmp[0..$];
                i += tmp.length;
                nu_freea(tmp);
            }
            
            // Teminate result.
            this.memory = cast(MemoryT)buffer;
            nu_terminate(memory);
        }
    }

    /**
        Copy-constructor
    */
    this(ref return scope inout(SelfType) rhs) inout @trusted {
        if (__ctfe) {
            this.flags |= STRFLAG_READONLY;
            this.memory = rhs.memory;
        } else if (rhs) {
            this.memory = rhs.memory.nu_idup;
        } else {
            nogc_zeroinit(cast(T[])this.memory);
        }
    }

    /**
        Constructs a string with the given size.
        The contents of the string will be zero-initialized.
    */
    this(uint size) {
        if (__ctfe) { } else {
            this.resize(size);
            nogc_zeroinit(this.memory);
        }
    }

    /**
        Move "constructor"
    */
    void opPostMove(ref typeof(this) other) {
        this.memory = other.memory;
        nogc_zeroinit(other.memory);
    }

    /**
        Clears the string, equivalent to resizing it to 0.
    */
    void clear() {
        this.resizeImpl(0);
    }

    /**
        Flips the endianness of the string's contents.

        Note:
            This is no-op for UTF-8 strings.

        Returns:
            The string instance.
    */
    auto ref flipEndian() {
        static if (CharType.sizeof > 1) {

            import nulib.memory.endian : nu_etoh, ALT_ENDIAN;
            cast(void)nu_etoh!(CharType, ALT_ENDIAN)(cast(CharType[])memory[0..$]);
        }

        return this;
    }

    /**
        Reverses the contents of the string

        Returns:
            The string instance.
    */
    auto ref reverse() {
        auto mmemory = cast(CharType[])memory;
        foreach(i; 0..memory.length/2) {
            auto a = memory[i];
            auto b = memory[$-(i+1)];

            mmemory[i] = b;
            mmemory[$-(i+1)] = a;
        }

        return this;
    }

    /**
        Take ownership of the memory owned by the string.

        If the string is tagged as read-only a copy of the string
        is returned.

        Returns:
            The memory which was owned by the nulib string,
            the nulib string is reset in the process.
    */
    immutable(T)[] take() {
        this.takeOwnershipImpl();
        
        auto mem = this.memory;
        this.resetImpl();
        return mem;
    }

    /**
        Resizes the string.

        Params:
            newLength = The amount of characters the string should be.

        Note:
            The contents when increasing the size of a string with this
            function is undefined. A null terminator will be appended 
            automatically.
    */
    void resize(size_t newLength) {
        this.resizeImpl(newLength);
    }

    /**
        Sets the value of the string.

        Params:
            other = The string to set this string to.

        Notes:
            This function will directly replace the internal store,
            as such, you are responsible for freeing prior memory
            where relevant.
    */
    void opAssign(U)(U other) @trusted
    if (isSomeString!U) {
        static if (is(StringCharType!U == StringCharType!SelfType)) {
            if (!(flags & STRFLAG_READONLY) && memory.ptr) 
                nu_free(cast(void*)this.memory.ptr);
            
            this.memory = other.sliceof.nu_dup();
            nu_terminate(memory);

            // Take ownership of our new memory.
            if (flags & STRFLAG_READONLY) 
                flags &= ~STRFLAG_READONLY;
        } else {
            auto val = otherToSelf(other.sliceof);
            this.memory = val;
        }
    }

    /**
        Appends a character to this string.
    */
    void opOpAssign(string op, U)(auto ref inout(U) value) @trusted
    if (op == "~" && isSomeChar!U) {
        
        // Don't insert null terminators.
        if (value == cast(U)0)
            return;
        
        this.resizeImpl(length+1);
        this.setCharImpl(cast(void*)(&memory[$-1]), value);
    }

    /**
        Appends a string to this string.
    */
    void opOpAssign(string op, U)(auto ref U other) @trusted
    if (op == "~" && isSomeString!U) {
        
        // Skip appending empty strings.
        if (other.sliceof.length == 0)
            return;

        size_t start = memory.length;
        static if (!is(StringCharType!U == StringCharType!SelfType)) {

            // We want the null terminator, so use this ugly pointer
            // arithmetic. We know enc will always have it anyways.
            auto otherSlice = otherToSelf(other);
            
            this.resizeImpl(memory.length+otherSlice.length);
            this.setRangeImpl(memory[start..$], otherSlice[0..$]);

            nu_freea(otherSlice);
        } else {
            auto otherSlice = other.sliceof;
            if (isOverlapping(memory, otherSlice)) {
                auto tmp = otherSlice.nu_dup();

                this.resizeImpl(memory.length+tmp.length);
                this.setRangeImpl(memory[start..$], tmp[0..$]);
                tmp = tmp.nu_resize(0);
                return;
            }

            this.resizeImpl(memory.length+otherSlice.length);
            this.setRangeImpl(memory[start..$], otherSlice[0..$]);
        }
    }

    /**
        Makes a nstring appended to this string.
    */
    auto opBinary(string op, R)(auto ref inout R rhs) inout
    if (op == "~") {

        // We can't be sure that the given strings won't be freed if we
        // passed them in to opOpAssign, as such we copy them.
        auto lhsv = this.sliceof.nu_dup();
        auto rhsv = rhs.sliceof.nu_dup();

        SelfType result;
        result ~= lhsv;
        result ~= rhsv;

        nu_freea(lhsv);
        nu_freea(rhsv);
        return result;
    }

    /**
        Makes a nstring prepended to this string.
    */
    auto opBinaryRight(string op, R)(auto ref inout R lhs) inout
    if (op == "~") {

        // We can't be sure that the given strings won't be freed if we
        // passed them in to opOpAssign, as such we copy them.
        auto lhsv = lhs.sliceof.nu_dup();
        auto rhsv = this.sliceof.nu_dup();

        SelfType result;
        result ~= lhsv;
        result ~= rhsv;

        nu_freea(lhsv);
        nu_freea(rhsv);
        return result;
    }
}

@("nstring: char append")
unittest {
    // appending a char
    nstring s;
    nwstring ws;
    ndstring ds;
    s  ~= 'c';
    ws ~= '\u4567';
    ds ~= '\U0000ABCD';
    assert(s == "c" 
       && ws == "\u4567"w 
       && ds == "\U0000ABCD"d);

    // Not working yet: append to itself
    s ~= s;
    assert(s == "cc");
}

@("nstring: append")
unittest {
    const(char)* cstr1 = "a zero-terminated string";
    const(wchar)* cstr2 = "hey";
    const(dchar)* cstr3 = "ho";

    nstring s;
    s ~= cast(string)null;
    s ~= "";
    s ~= cstr1;
    assert(s == "a zero-terminated string");

    nwstring ws;
    ws ~= cstr2;
    assert(ws.length == 3);

    ndstring wd;
    wd ~= cstr3;
    assert(wd == "ho"d);
}

@("nstring: concat")
unittest {
    auto str1 = nstring("Hello, ") ~ "world!";
    assert(str1 == "Hello, world!", str1.sliceof);

    auto str2 = nstring("Hello, ", "world", " 2!"w);
    assert(str2 == "Hello, world 2!");
}

@("nstring: concat convert")
unittest {
    import std.utf : toUTF8;

    auto str1 = nstring("Hello, ") ~ nwstring("world!"w);
    assert(str1 == "Hello, world!", str1.sliceof);

    auto str2 = ndstring("Hello, ") ~ nstring("world!");
    assert(str2 == "Hello, world!"d, str2.sliceof.toUTF8);

    auto str3 = nstring("Hello, ") ~ "world!"w;
    assert(str3 == "Hello, world!", str3.sliceof.toUTF8);
}

@("nstring: reverse")
unittest {
    nstring str = "Test";
    assert(str.reverse() == "tseT");
}

@("nstring: flipEndian")
unittest {
    nwstring str = "Test"w;
    assert(str.flipEndian() == "\u5400\u6500\u7300\u7400"); // "Test" UTF-16 code points, but endian flipped.
}

@("nstring: string in map")
unittest {
    import nulib.collections.map : map;
    map!(nstring, int) kv;
    kv[nstring("uwu")] = 42;

    assert(kv[nstring("uwu")] == 42);
}

@("nstring: length")
unittest {
    nstring str = "Test string";
    assert(str.usage() == 11);
    assert(str.length() == 11);
    assert(str.realLength() == 12);
}

@("nstring: emptiness")
unittest {
    nstring str;

    assert(str.empty());

    // Should add null terminator.
    str.clear();
    assert(str.empty);
    assert(str.ptr is null);
}

//
//      C and D string handling utilities
//

/**
    Gets the slice equivalent of the input string.
*/
auto sliceof(T)(auto ref T str) @nogc nothrow
if(isSomeString!T) {
    if (__ctfe) {
        return str[0..(str.stringof.length)];
    } else {
        static if (isSomeCString!T) {
            return str[0..nu_strlen(str)];
        } else {
            return str[0..$];
        }
    }
}

@("sliceof")
unittest {
    const(char)* str1 = "Hello, world!";
    const(char)[] str2 = "Hello, world!";
    nstring str3 = "Hello, world!";
    
    assert(str1.sliceof == str1.sliceof);
    assert(str3.sliceof == str2.sliceof, str3.sliceof);
}

/**
    Gets a slice from a null-terminated string.

    Params:
        str = the null terminated string to slice.

    Returns:
        A new slice over the string, stopping before the null terminator.
        If $(D str) is not null terminated the return value
        is undefined and likely corrupted.
*/
inout(T)[] fromStringz(T)(inout(T)* str) @system @nogc pure nothrow
if (isSomeChar!T) {
    return str ? str[0 .. nu_strlen!T(str)] : null;
}

/**
    Gets the length of a null-terminated string.

    Params:
        str = the string to check the length of.
    
    Returns:
        The length of the string in code units.
        If $(D str) is not null terminated the return value
        is undefined.
*/
size_t nu_strlen(T)(inout(T)* str) @system @nogc pure nothrow
if (isSomeChar!T) {
    const(T)* p = str;
    while (*p)
        ++p;
    
    return p - str;
}