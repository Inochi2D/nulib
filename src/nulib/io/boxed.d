/**
    Boxed Types

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.io.boxed;
import numem;
import nulib.io.serialize;

/**
    A boxed D base type.
*/
class Boxed(T) : NuObject, ISerializable, IDeserializable {
private:
    T value;

public:

    // Destructor
    ~this() { nogc_delete(value); }

    /**
        Constructor
    */
    this(T value) { this.value = value; }

    /**
        The name of the boxed type.
    */
    final
    @property string typeName() { return T.stringof; }

    /**
        Unboxes the value in the type.
    */
    final
    T unbox() { return value; }

    /**
        Called on the object to serialize it using the 
        given (de)serializer.

        Params:
            serde = the (de)serializer to use.
    */
    void serialize(ref Serde serde) {
        return serde.serialize!T(value);
    }

    /**
        Called on the object to deserialize it using the 
        given (de)serializer.

        Params:
            serde = the (de)serializer to use.
    */
    void deserialize(ref Serde serde) {
        return serde.deserialize!T(value);
    }
}