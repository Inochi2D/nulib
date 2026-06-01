/**
    NuLib 128-bit integers.

    Based on mir-algorithm.

    Copyright:
        Copyright © 2020, Ilia Ki, Kaleidic Associates Advisory Limited, Symmetry Investments
        Copyright © 2025, Inochi2D Project
    
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:
    	Ilia Ki
    	Kaleidic Associates Advisory Limited
    	Symmetry Investments
        Luna Nielsen
*/
module nulib.math.bigint;
import nulib.math;

// TODO: Get permission to re-license this code under the boost license.

/**
	Stack-allocated fixed-length unsigned integer.

	Params:
		sz = Size of the integer in bits.
*/
struct UInt(size_t sz)
if (sz % (size_t.sizeof * 8) == 0 && sz >= size_t.sizeof * 8) {
private:
@nogc:
	enum arrsz = sz / (size_t.sizeof * 8);
	size_t[arrsz] data;

public:

	/**
		Size of the integer in bits.	
	*/
	enum size = sz;

	/**
		Maximum value that this type can represent.	
	*/
	enum UInt!size max = (() { UInt!size v; v.data[0..$] = size_t.max; return v; })();

	/**
		Minimum value that this type can represent.	
	*/
	enum UInt!size min = UInt!(size).init;

	/**
		Constructs a unsigned integer from a series of integers.

		Params:
			data = The data to set for the integer.
	*/
    this(size_t N)(auto ref const size_t[N] data)
	if (N && N <= this.data.length) {
        version(LittleEndian)
            this.data[0..N] = data;
        else
            this.data[$-N..$] = data;
    }

    /**
		Constructs a unsigned integer from another integer.

		Params:
			value = The integer to copy the data from.
	*/
    this(T)(auto ref const T value)
	if (isBigUInt!T) {
		static if (T.size <= typeof(this).size) {
	        this(value.data);
	    } else {
	    	enum N = T.arrsz < this.arrsz ? T.arrsz : this.arrsz;
            this.data[0..N] = value.data[0..N];
	    }
    }

    /**
		Constructs a unsigned integer from another integer.

		Params:
			value = The integer to copy the data from.
	*/
    this(T)(auto ref const T value) 
    if (__traits(isIntegral, T)) {
    	static if (value.sizeof <= size_t.sizeof) {
    		this.data[0] = value;
    	} else {
	    	this.data[0] = cast(T)value;
	    	this.data[1] = cast(T)(data >> T.sizeof*8);
    	}
    }




    //
    //			EQUALITY
    //

    // MATCHING SIZES.
    bool opEquals(T)(auto ref const T other) const 
    if (isBigUInt!T && T.size == this.size) {
    	static foreach(i; 0..data.length)
    		if (this.data[i] != other.data[i])
    			return false;

    	return true;		
    }

    // MISMATCHED SIZES.
    bool opEquals(T)(auto ref const T other) const 
    if (isBigUInt!T && T.size != this.size) {
    	return this.opEquals(UInt!size(other));	
    }

    // NORMAL INTEGERS.
    bool opEquals(T)(T other) const
    if (__traits(isIntegral, T)) {
    	return this.opEquals(typeof(this)(other));
    }




    //
    //			ARITHMETIC
    //

}

/**
	Gets whether the given type is a big integer of some kind.	
*/
enum isBigUInt(T) = is(T == UInt!U, U...);

/**
	128-bit unsigned integer.	
*/
alias uint128_t = UInt!128;


@("BigInt!128")
unittest {
	UInt!128 a = 24;
	UInt!256 b = 24;

	assert(a == b);
}