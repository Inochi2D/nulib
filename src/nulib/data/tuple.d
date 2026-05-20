/**
    Tuples
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
*/
module nulib.data.tuple;

/**
    A tuple, essentially a struct constructed from its template
    arguments.

    Example:
        $(D_CODE
            NamedTuple!(int, "a", int, "b") myTuple;
            myTuple.a = 42;
            myTuple.b = 128;
        )
*/
struct NamedTuple(Args...) if (Args.length > 0) {
public:
@nogc:
    static assert(Args.length % 2 == 0, "Tuples must be constructed in the form of Tuple!(Type, \"name\", ...)!");
    
    static foreach(i; 0..Args.length/2) {
        mixin(Args[(i*2)], " ", Args[(i*2)+1], ";");    
    }
}

@("NamedTuple")
unittest {
    NamedTuple!(int, "a", int, "b") myTuple = { 1, 2 };
    assert(myTuple.a == 1);
    assert(myTuple.b == 2);
}

/**
    A tuple which has automatically generated member names.
    The names are in order of what was passed to the tuple.

    Example:
        $(D_CODE
            Tuple!(int, int) myTuple;
            myTuple.item1 = 42;
            myTuple.item2 = 128;
        )
*/
struct Tuple(Args...) if (Args.length > 0) {
    import std.conv : text;

    static foreach(i; 0..Args.length) {
        mixin(Args[i], " item", (i+1).text, ";");   
    }
}

@("Tuple")
unittest {
    Tuple!(int, int) myTuple2 = { 1, 2 };
    assert(myTuple2.item1 == 1);
    assert(myTuple2.item2 == 2);
}