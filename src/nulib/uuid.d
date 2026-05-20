module nulib.uuid;
import nulib.random;
import nulib.string;
import nulib.memory.endian;
import nulib.text.ascii;
import nulib.conv;
import numem;

/**
    UUID Variants
*/
enum UUIDVariant {
    ncs,
    rfc4122,
    microsoft,
    reserved
}

/**
    Creates a UUID object at compile time from a UUID string.

    Params:
        uuid = The UUID string to generate a UUID object from.
        forceMS = Whether to force the microsoft format.
*/
template CTUUID(string uuid, bool forceMS = false) {
    UUID genUUID(string slice) {
        UUID uuid;

        if (__ctfe) {
            if (!UUID.validate(slice))
                return uuid;

            // Get from string
            uuid.time_low = parseHex!uint(slice[0..8]);
            uuid.time_mid = parseHex!ushort(slice[9..13]);
            uuid.time_hi_and_version = parseHex!ushort(slice[14..18]);
            uuid.clk_seq = parseHex!ushort(slice[19..23]);

            // Get bytes
            foreach(i; 0..UUID.node.length) {
                uuid.node[i] = parseHex!ubyte(slice[24+(i*2)..24+(i*2)+2]);
            }

            // Flip clk_seq if need be.
            uuid.handleMsFormat(forceMS);
        }
        return uuid;
    }

    enum CTUUID = genUUID(uuid);
}

/**
    RFC4122 compliant UUIDs
*/
struct UUID {
@nogc nothrow:
private:
    enum VERSION_BITMASK = 0b11110000_00000000;

    // NCS Variant Bits
    enum V_NCS_BITMASK = 0b11000000_00000000;
    enum V_NCS_BITS = 0b10000000_00000000;

    // RFC Variant Bits
    enum V_RFC_BITMASK = 0b11100000_00000000;
    enum V_RFC_BITS = 0b11000000_00000000;

    // Microsoft Variant Bits
    enum V_MSF_BITMASK = 0b11100000_00000000;
    enum V_MSF_BITS = 0b11100000_00000000;

    union {
        struct {
            uint time_low;
            ushort time_mid;
            ushort time_hi_and_version;
            ushort clk_seq;
            ubyte[6] node;
        }
        ubyte[16] bdata;
        ulong[2] ldata;
    }
    
    this(ulong[2] data) inout {
        this.ldata = data;
    }

    // Helper that swaps bytes in MS format.
    void handleMsFormat(bool force = false) {
        if ((clk_seq & V_MSF_BITMASK) == V_MSF_BITS || force) {
            ushort old_seq = clk_seq;
            this.clk_seq = 
                (old_seq >> 8) | 
                ((old_seq & 0xFF) << 8);
        }
    }

public:

    /**
        Length of a UUID string
    */
    enum uuidStringLength = 36;

    /**
        Special "nil" UUID
    */
    enum UUID nil = UUID([0LU, 0LU]);
    alias min = nil;

    /**
        Special "max" UUID
    */
    enum UUID max = UUID([ulong.max, ulong.max]);

    /**
        The underlying data of the UUID.
    */
    @property ubyte[] data() return { return this.bdata[0..$]; }

    /**
        The version of the UUID structure
    */
    @property int uuidVersion() {
        return cast(int)(time_hi_and_version >> 12);
    }

    deprecated("use .uuidVersion instead!")
    alias getVersion = uuidVersion;

    /**
        The variant of the UUID structure
    */
    @property UUIDVariant uuidVariant() {
        if ((clk_seq & V_MSF_BITMASK) == V_MSF_BITS) 
            return UUIDVariant.microsoft;
        if ((clk_seq & V_RFC_BITMASK) == V_RFC_BITS) 
            return UUIDVariant.rfc4122;
        if ((clk_seq & V_NCS_BITMASK) == V_NCS_BITS) 
            return UUIDVariant.ncs;
        
        return UUIDVariant.reserved;
    }
    
    deprecated("use .uuidVariant instead!")
    alias getVariant = uuidVariant;

    /**
        Constructs a UUID from the specified byte slice
    */
    this(ubyte[16] bytes) {
        this.bdata = bytes;
        this.time_low = nu_ntoh(this.time_low);
        this.time_mid = nu_ntoh(this.time_mid);
        this.time_hi_and_version = nu_ntoh(this.time_hi_and_version);
    }

    /**
        Provides compatibility with .NET's Guid struct.
    */
    this(uint time_low, ushort time_mid, ushort time_hi_and_version, ubyte clk0, ubyte clk1, ubyte d0, ubyte d1, ubyte d2, ubyte d3, ubyte d4, ubyte d5) {
        this.time_low = time_low;
        this.time_mid = time_mid;
        this.time_hi_and_version = time_hi_and_version;
        this.clk_seq = clk0 << 8 | clk1;
        this.node[0] = d0;
        this.node[1] = d1;
        this.node[2] = d2;
        this.node[3] = d3;
        this.node[4] = d4;
        this.node[5] = d5;

        this.handleMsFormat();
    }   

    /**
        Constructs a UUID from the specified string.
    */
    this(string text) {
        this = UUID.parse(text);
    }

    /**
        Validates the correctness of a UUID string.

        Params:
            slice = The string slice to validate
        
        Returns:
            $(D true) if the slice is a valid UUID string,
            $(D false) otherwise.
    */
    static bool validate(string slice) {

        // Incorrect length
        if (slice.length != UUID.uuidStringLength)
            return false;

        foreach(i; 0..UUID.uuidStringLength) {
            
            // Dash positions
            if (i == 8 || i == 13 || i == 18 || i == 23) {
                if (slice[i] != '-') 
                    return false;
                else
                    continue;
            }

            // Hex positions
            if (!isHex(slice[i]))
                return false;
        }

        return true;
    }

    /**
        Creates a new UUIDv3 with a specified random number generator.

        Params:
            random = The random number generator to use.
        
        Returns:
            A new psuedorandomly generated UUID.
    */
    static UUID createRandom(RandomBase random) {
        UUID uuid;
        uuid.time_hi_and_version &= 0x0FFF;
        uuid.time_hi_and_version |= (3 << 12);
        uuid.clk_seq &= 0x3F;
        uuid.clk_seq |= 0x80;

        ubyte[] dst = uuid.node[0..$];
        random.next(dst);
        return uuid;
    }

    /**
        Tries to parse a UUID from a string.
        
        Params:
            slice = The string slice to parse.

        Returns:
            A new UUID parsed from the string, or a nil UUID on failure.
    */
    static UUID parse(string slice) {
        if (!UUID.validate(slice))
            return UUID.nil;

        UUID uuid;

        // Get from string
        uuid.time_low = slice[0..8].toInt!uint(16);
        uuid.time_mid = slice[9..13].toInt!ushort(16);
        uuid.time_hi_and_version = slice[14..18].toInt!ushort(16);
        uuid.clk_seq = slice[19..23].toInt!ushort(16);

        // Get bytes
        foreach(i; 0..6) {
            size_t start = 24+(i*2);
            uuid.node[i] = slice[start..start+2].toInt!ubyte(16);
        }
        
        uuid.handleMsFormat();
        return uuid;
    }

    /**
        Returns byte stream from UUID with data in network order.
    */
    ubyte[16] toBytes() {
        UUID datacopy;
        datacopy.bdata[0..$] = bdata[0..$];

        datacopy.time_low = nu_ntoh(this.time_low);
        datacopy.time_mid = nu_ntoh(this.time_mid);
        datacopy.time_hi_and_version = nu_ntoh(this.time_hi_and_version);
        return datacopy.bdata;
    }

    /**
        Returns UUID string
    */
    nstring toString() {
        import nulib.c.stdio : snprintf;

        char[uuidStringLength+1] buffer;
        snprintf(
            cast(char*)buffer.ptr,
            buffer.length,
            "%0.8x-%0.4hx-%0.4hx-%0.4hx-%.2hhx%.2hhx%.2hhx%.2hhx%.2hhx%.2hhx", 
            time_low, 
            time_mid, 
            time_hi_and_version,
            clk_seq,
            node[0],
            node[1],
            node[2],
            node[3],
            node[4],
            node[5],
        );
        
        nstring ret = nstring(cast(string)buffer[0..uuidStringLength]);
        return ret;
    }

    /**
        Checks equality between 2 UUIDs.
    */
    bool opEquals(const UUID other) const {
        return this.ldata[0] == other.ldata[0] && this.ldata[1] == other.ldata[1];
    }

    /**
        Compares 2 UUIDs lexically.

        Lexical order is NOT temporal!
    */
    int opCmp(const UUID other) const {

        // First check things which are endian dependent.
        if (this.time_low != other.time_low) 
            return this.time_low < other.time_low;

        if (this.time_mid != other.time_mid) 
            return this.time_mid < other.time_mid;

        if (this.time_hi_and_version != other.time_hi_and_version) 
            return this.time_hi_and_version < other.time_hi_and_version;
        
        // Then check all the nodes
        static foreach(i; 0..node.length) {
            if (this.node[i] < other.node[i]) return -1;
            if (this.node[i] > other.node[i]) return 1;
        }

        // They're the same.
        return 0;
    }
}

@("uuid: parsing")
unittest {
    const string[4] tests = [
        "ce1a553c-762d-11ef-b864-0242ac120002",
        "56ba8f28-d9aa-4452-80c1-4ce66d064f6c",
        "01920815-46af-71fa-9025-35d7592a401b",
        "7f204bc7-53fe-4ffb-acaf-3f0cd0cf69cb"
    ];

    const UUIDVariant[4] variants = [
        UUIDVariant.ncs,
        UUIDVariant.ncs,
        UUIDVariant.ncs,
        UUIDVariant.ncs,
    ];

    const int[4] versions = [
        1,
        4,
        7,
        4
    ];

    foreach(i; 0..4) {
        import std.format : format;
        import std.conv : text;
        UUID uuid = UUID.parse(tests[i]);

        assert(
            uuid.uuidVariant == variants[i],
            "Expected %s, got %s".format(variants[i], uuid.uuidVariant)
        );

        assert(
            uuid.uuidVersion == versions[i], 
            "uuid=%s (test %s), version=%s, expected=%s!".format(tests[i], i+1, uuid.uuidVersion, versions[i])
        );
    }
}

@("uuid: comparison")
unittest {
    UUID uuid1 = UUID.parse("ce1a553c-762d-11ef-b864-0242ac120002");
    UUID uuid2 = UUID.parse("56ba8f28-d9aa-4452-80c1-4ce66d064f6c");
    UUID uuid3 = UUID.parse("ce1a553c-762d-11ef-b864-0242ac120002");

    assert(uuid1 == uuid3);
    assert(uuid1 != uuid2);
}

@("uuid: toString")
unittest {
    import std.format : format;

    UUID uuid1 = UUID.parse("ce1a553c-762d-11ef-b864-0242ac120002");
    nstring str = uuid1.toString();
    assert(str == "ce1a553c-762d-11ef-b864-0242ac120002", "Expected %s, got %s".format("ce1a553c-762d-11ef-b864-0242ac120002", str[]));
}

@("uuid: generation")
unittest {
    import numem.core;

    Random random = nogc_new!Random(42);
    scope(exit) nogc_delete(random);

    UUID uuid = UUID.createRandom(random);
    scope(exit) nogc_delete(uuid);
    assert(uuid != UUID.nil);
}

@("uuid: UUID.validate")
unittest {
    assert( UUID.validate("6ba7b810-9dad-11d1-80b4-00c04fd430c8"));
    assert( UUID.validate("449ed9d5-6810-44c6-9506-504ceeb27e0d"));
    assert(!UUID.validate(""));
    assert(!UUID.validate("6ba7b81i-9dad-11d1-80b4-00c04fd430c8"));
    assert(!UUID.validate("\0\0\0\0\0\0\0\0\0\0\0\0\0\0"));
}