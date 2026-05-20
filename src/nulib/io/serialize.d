/**
    Serialization Interface

    Interfaces for creating classes which may be serialized and deserialized.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.io.serialize;
import nulib.string;
import numem;

/**
    Interface a class may implement to indicate it can be serialized.
*/
interface ISerializable {
@nogc:

    /**
        Called on the object to serialize it using the 
        given (de)serializer.

        Params:
            serde = the (de)serializer to use.
    */
    void serialize(ref Serde serde);
}

/**
    Gets whether the type can be serialized using an
    elaborate serializer function.
*/
enum hasElaborateSerializer(T) =
    is(T : ISerializable) ||
    is(typeof((ref Serde serde) { auto t = T.init; t.serialize(serde); }));

/**
    Interface a class may implement to indicate it can be deserialized.
*/
interface IDeserializable {
@nogc:

    /**
        Called on the object to deserialize it using the 
        given (de)serializer.

        Params:
            serde = the (de)serializer to use.
    */
    void deserialize(ref Serde serde);
}

/**
    Gets whether the type can be deserialized using an
    elaborate serializer function.
*/
enum hasElaborateDeserializer(T) =
    is(T : IDeserializable) ||
    is(typeof((ref Serde serde) { auto t = T.init; t.deserialize(serde); }));

/**
    A (de)serializer.
*/
abstract
class Serde : NuObject {
private:
@nogc:
    SerdeContext ctx;

protected:

    /**
        Called when the serialization context is initialized.
    */
    abstract SerdeContext onInit();

    /**
        A serialization function which serializes a string.

        Params:
            value = The value to serialize.
    */
    abstract void serializeString(string value);

    /**
        A serialization function which serializes a signed integer.
        (max 64-bit)

        Params:
            value = The value to serialize, sign extended.
            bytes = The actual amount of bytes to serialize.
    */
    abstract void serializeInt(long value, ubyte bytes);

    /**
        A serialization function which serializes an unsigned
        integer. (max 64-bit)

        Params:
            value = The value to serialize, sign extended.
            bytes = The actual amount of bytes to serialize.
    */
    abstract void serializeUInt(ulong value, ubyte bytes);

    /**
        A serialization function which serializes a floating
        point number. (max 64-bit)

        Params:
            value = The value to serialize.
            bytes = The actual amount of bytes to serialize.
    */
    abstract void serializeFloat(double value, ubyte bytes);

    /**
        A deserialization function which deserializes a string.

        Returns:
            The deserialized value
    */
    abstract nstring deserializeString();

    /**
        A serialization function which serializes a signed integer.
        (max 64-bit)

        Params:
            bytes = The amount of bytes to deserialize.

        Returns:
            The deserialized value
    */
    abstract long deserializeInt(ubyte bytes);

    /**
        A serialization function which serializes an unsigned
        integer. (max 64-bit)

        Params:
            bytes = The amount of bytes to deserialize.

        Returns:
            The deserialized value
    */
    abstract ulong deserializeUInt(ubyte bytes);

    /**
        A serialization function which serializes a floating
        point number. (max 64-bit)

        Params:
            bytes = The amount of bytes to deserialize.

        Returns:
            The deserialized value
    */
    abstract double deserializeFloat(ubyte bytes);

    /**
        Begins a complex serialization context.
    */
    abstract SerdeContext beginComplexContext();

    /**
        Ends a complex serde context.
    */
    abstract void endComplexContext(SerdeContext ctx);

public:

    // Destructor
    ~this() { nogc_delete(ctx); }

    /**
        Constructs a Serde object.
    */
    this() {
        ctx = this.onInit();
    }

    /**
        The name of the format that the (de)serializer 
        supports.
    */
    abstract @property string format();

    /**
        The public serialization interface.
    */
    void serialize(T)(auto ref T item) {
        static if (is(T : string)) {
            serializeString(item);
        } else static if (__traits(isFloating, T)) {
            serializeFloat(cast(double)item, T.sizeof);
        } else static if (__traits(isIntegral, T) && __traits(isUnsigned, T)) {
            serializeUInt(cast(ulong)item, T.sizeof);
        } else static if (__traits(isIntegral, T) && !__traits(isUnsigned, T)) {
            serializeInt(cast(ulong)item, T.sizeof);
        } else static if (hasElaborateSerializer!T) {
            Serde self = this;
            item.serialize(self);
        } static assert(0, "Can't serialize given type "~T.stringof~".");
    }
    
    /**
        The public deserialization interface.
    */
    void deserialize(T)(auto ref T item) { 
        static if (is(T : string)) {
            serializeString(item);
        } else static if (__traits(isFloating, T)) {
            serializeFloat(cast(double)item, T.sizeof);
        } else static if (__traits(isIntegral, T) && __traits(isUnsigned, T)) {
            serializeUInt(cast(ulong)item, T.sizeof);
        } else static if (__traits(isIntegral, T) && !__traits(isUnsigned, T)) {
            serializeInt(cast(ulong)item, T.sizeof);
        } else static if (hasElaborateDeserializer!T) {
            Serde self = this;
            item.deserialize(self);
        } static assert(0, "Can't deserialize given type "~T.stringof~".");
    }
}

/**
    A context used during (de)serialization to traverse complex
    nested serialization trees.
*/
abstract
class SerdeContext : NuObject  {
private:
    Serde owner_;

public:
@nogc:

    /**
        Constructor for a context.
    */
    this(Serde owner) { this.owner_ = owner; }

    /**
        The owner object which created the context.
    */
    final
    @property Serde owner() { return owner_; }

    /**
        Begins an object within the context.
    */
    abstract SerdeContext beginObject();

    /**
        Ends an object within the context.
    */
    abstract void endObject(SerdeContext object);

    /**
        Begins a data range within the context.
    */
    abstract SerdeContext beginRange();

    /**
        Ends a data range within the context.
    */
    abstract void endRange(SerdeContext object);
}
