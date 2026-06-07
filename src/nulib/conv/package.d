/**
    nulib conversion functions.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.conv;
import numem.core.math;
import numem.core.traits;
import nulib.string;

public import nulib.conv.integral;

// TODO:    This entire module should be rewritten into pure D.
//          Relying on the C standard library here is probably
//          not the best idea for portability.



/**
    Converts the given value to another type, if possible.

    Various methods will be attempted to perform the conversion,
    depending on the source and destination type.

    Params:
        value = The value to convert.

    Returns:
        The converted value, or $(D TTo)'s initial value on failure.
*/
Unqual!TTo to(TTo, TFrom)(TFrom value) @nogc nothrow {
    static if (is(typeof(TFrom.opCast!TTo))) {

        // cast(TTo)value
        return value.opCast!TTo();
    } else static if (isSomeString!TTo && is(typeof(TFrom.toString))) {
        
        // value.toString()
        return value.toString();
    } else static if (__traits(isIntegral, TTo) && isSomeString!TFrom) {

        // value.parseInt!TTo()
        return parseInt!TTo(value);
    } else {
        debug static assert(0, "Can't convert "~TFrom.stringof~" to "~TTo.stringof~"!");
        return typeof(return).init;
    }
}