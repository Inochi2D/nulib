/**
    Variants
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
*/
module nulib.data.variant;
import numem.core.traits;
import numem.core.exception;
import numem.core.hooks;
import numem.optional;
import numem.lifetime;

/**
    A type which can contain any type in the language, stored on the heap.

    Note:
        The ownership of a variant depends on the API, the $(D Variant) itself
        does not own its memory. You may call the $(D free) method to free any
        memory owned by the variant.
*/
struct Variant {
private:
    // Helpers that are not nogc, to allow usage with druntime.
    static bool isType(T)(TypeInfo id) => id == typeid(T);
    static string getTypeName(TypeInfo id) => id.toString();

@nogc:
    TypeInfo id;
    void* data;

    // Internal ctor
    this(TypeInfo id, void* data) @trusted nothrow {
        this.id = id;
        this.data = data;
    }

public:
    alias isInitialized this;

    /**
        An empty variant.
    */
    enum empty = Variant(null, null);

    /**
        Whether the variant is empty.
    */
    @property bool isEmpty() @trusted nothrow pure => id is null || data is null;

    /**
        Whether the variant has data.
    */
    @property bool isInitialized() @trusted nothrow pure => id !is null && data !is null;

    /**
        Constructor
    */
    this(T)(auto ref T value) @trusted nothrow {
        static if (is(T == Variant)) {
            this.id = value.id;
            this.data = value.data;
        } else {
            this.id = typeid(T);
            static if (isHeapAllocated!T)
                this.data = cast(void*)value;
            else {
                this.data = nu_malloc(T.sizeof);
                *(cast(T*)this.data) = value.move();
            }
        }
    }

    /**
        Gets whether the variant contains the given type.

        Returns:
            Whether the variant is storing a type with the given
            type's type id.
    */
    bool has(T)() @trusted nothrow {
        return id !is null && assumeNoThrowNoGC(&isType!T, id);
    }

    /**
        Tries to get the content of the variant.

        Returns:
            A $(D Option) value either containing the value
            or invalid state. 
    */
    Option!T tryGet(T)() @trusted nothrow {
        if (!has!(T)())
            return none!T();
        
        static if (isHeapAllocated!T)
            return some!T(cast(T)data);
        else
            return some!T(*cast(T*)data);
    }

    /**
        Gets the content of the variant.

        Note:
            This function will fatally crash if the variant
            doesn't contain a value of the given type!
    */
    T get(T)() @trusted nothrow {
        if (!has!(T)()) {
            import nulib.string : nstring;
            nu_fatal(nstring("Type mismatch between ", T.stringof, " and ", assumeNoThrowNoGC(&getTypeName, id), "!").take());
        }
        
        static if (isHeapAllocated!T)
            return cast(T)data;
        else
            return *cast(T*)data;
    }

    /// Allows assigning the variant to a value.
    void opAssign(T)(auto ref T value) @trusted nothrow {
        static if (is(T == Variant)) {
            this.id = value.id;
            this.data = value.data;
        } else {
            this.id = typeid(T);
            static if (isHeapAllocated!T)
                this.data = cast(void*)value;
            else {
                this.data = nu_malloc(T.sizeof);
                *(cast(T*)this.data) = value.move();
            }
        }
    }

    /**
        Gets whether the variant is the same as another variant.
    */
    bool opEquals(T)(T other) @trusted nothrow {
        return other.data is data;
    }

    /**
        Frees the memory stored in the variant.

        Note:
            This will NOT call any destructors on the type in
            question. 
    */
    void free() @trusted nothrow {
        this.id = null;
        if (data) {
            nu_free(data);
            this.data = null;
        }
    }
}

@("Variant: get, has, assign")
unittest {

    // ctor initialize.
    Variant v = 42;
    assert(v);
    assert(v.has!int);
    assert(!v.has!long);
    assert(v.tryGet!int);
    assert((v.tryGet!int).get == 42);
    v.free();

    // assign initialize
    v = 42;
    assert(v);
    assert(v.has!int);
    assert(v.tryGet!int);
    assert((v.tryGet!int).get == 42);
    Variant v2 = v;
    assert(v == v2); // Is it a reference to the same data?

    // Free one and empty the other.
    v.free();
    v2 = Variant.empty;
    assert(v == v2 && !v);
}

@("Variant: arrays")
unittest {
    Variant v = [0, 1, 2, 3].nu_dup();
    assert(v);
    assert(v.has!(int[]));
    assert(v.tryGet!(int[]).get == [0, 1, 2, 3]);
    v.free();
}