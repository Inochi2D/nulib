/**
    SumTypes, this is mostly taken from libphobos.
    
    Copyright:
        Copyright © 2005-2009, The D Language Foundation.
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Paul Backus,
        Luna Nielsen
*/
module nulib.data.sumtype;
import numem.core.lifetime : forward;
import numem.core.traits;
import numem.core.meta;
import numem;

/**
    Gets whether the given type is a sumtype.
*/
enum isSumType(T) = is(T : SumType!U, U...);

/**
    A sum type
*/
struct SumType(Types...) if (Types.length > 0) {
private:
@nogc:
    enum bool canHoldTag(T) = Types.length <= T.max;
    alias Tag = Filter!(canHoldTag, AliasSeq!(ubyte, ushort, uint, ulong))[0];

    // Meta-info enums.
    enum hasDtor = anySatisfy!(hasElaborateDestructor, Types);
    enum hasCCtor = anySatisfy!(hasElaborateCopyConstructor, Types);

    // Sumtype storage
    union Storage {
        static foreach(typeId, T; Types) {
            mixin("T ", memberNameOf!typeId, ";");
        }
    }

    Tag tag;
    Storage storage;

    @trusted
    auto ref getByIndex(size_t tid)() inout 
    if (tid < Types.length) {
        assert(tag == tid, "Does not contain requested type!");
        return storage.tupleof[tid];
    }

public:

    /**
        The types which the sumtype may contain
    */
    alias AllowedTypes = Types;

    /**
        Destructor
    */
    static if (hasDtor)
    ~this() {
        this.match!destroyIfOwner;
    }

    static foreach(typeId, T; Types) {

        // Constructor
        this()(auto ref T value) {
            static if (isMovable!T) {
                storage.tupleof[typeId] = value.move();
            } else {
                storage.tupleof[typeId] = forward!value;
            }

            static if (Types.length > 1)
                this.tag = typeId;
        }

        // Assignment
        static if (isAssignable!T) {
            ref SumType opAssign(T rhs) {
                import std.format : format;
                alias OtherTypes = AliasSeq!(Types[0..typeId], Types[typeId+1..$]);
                this.match!destroyIfOwner;

                static if (isMovable!T) {
                    mixin(q{
                        Storage newStorage = {
                            %s: forward!rhs
                        };
                    }.format(memberNameOf!typeId));
                } else {
                    mixin(q{
                        Storage newStorage = {
                            %s: __ctfe ? rhs : forward!rhs
                        };
                    }.format(memberNameOf!typeId));
                }

                storage = newStorage;
                static if (Types.length > 1)
                    this.tag = typeId;
                
                return this;
            }
        }

    }
}

/**
    Gets whether the given handler can match any of the given types.
    
    See the documentation for $(D match) for a full explanation of how matches are
    chosen.
*/
template canMatch(alias handler, Types...)
if (Types.length > 0) {
    enum canMatch = is(typeof((ref Types args) { return handler(args); }));
}

/**
    Calls a type-appropriate function with the value held in a [SumType].

    For each possible type the [SumType] can hold, the given handlers are
    checked, in order, to see whether they accept a single argument of that type.
    The first one that does is chosen as the match for that type. (Note that the
    first match may not always be the most exact match.
    See ["Avoiding unintentional matches"](#avoiding-unintentional-matches) for
    one common pitfall.)

    Every type must have a matching handler, and every handler must match at
    least one type. This is enforced at compile time.

    Handlers may be functions, delegates, or objects with `opCall` overloads. If
    a function with more than one overload is given as a handler, all of the
    overloads are considered as potential matches.

    Templated handlers are also accepted, and will match any type for which they
    can be [implicitly instantiated](https://dlang.org/glossary.html#ifti).
    (Remember that a $(DDSUBLINK spec/expression,function_literals, function literal)
    without an explicit argument type is considered a template.)

    If multiple [SumType]s are passed to match, their values are passed to the
    handlers as separate arguments, and matching is done for each possible
    combination of value types. See ["Multiple dispatch"](#multiple-dispatch) for
    an example.

    Returns:
        The value returned from the handler that matches the currently-held type.
*/
template match(handlers...) {
    auto ref match(SumTypes...)(auto ref SumTypes args)
    if (allSatisfy!(isSumType, SumTypes)) {
        return matchImpl!(true, handlers)(args);
    }
}

template has(T) {

    /**
        The actual `has` function.

        Params:
            self = the `SumType` to check.

        Returns: true if `self` contains a `T`, otherwise false.
    */
    bool has(Self)(auto ref Self self)
    if (isSumType!Self) {
        return self.match!checkType;
    }

    // Helper to avoid redundant template instantiations
    private
    bool checkType(Value)(ref Value value) {
        return is(Value == T);
    }
}

/**
    Accesses a `SumType`'s value.

    The value must be of the specified type. Use [has] to check.

    Params:
        T = the type of the value being accessed.
*/
template get(T) {
    auto ref T get(Self)(auto ref Self self)
    if (isSumType!Self) {
        static if (__traits(isRef, self))
            return self.match!(getLValue!(T));
        else
            return self.match!(getRValue!(T));
    }
    
    private
    ref T getLValue(Value)(ref Value value) {
        static if (is(Value == T))
            return value;
        else
            assert(false, "Could not get value!");
    }
    
    private
    T getRValue(Value)(ref Value value) {
        static if (is(Value == T)) {
            static if(is(typeof(move(value))))
                return __ctfe ? value : move(value);
            else
                return value;
        } else return T.init;
    }
}

private:

template iota(size_t n) {
    alias iota = AliasSeq!();

    static foreach(i; 0..n)
        iota = AliasSeq!(iota, n);
}

/*
    Creates a member name from an ID, used for procedual
    member generation.
*/
template memberNameOf(size_t id) {
    import std.conv : text;
    enum memberNameOf = "value_"~id.text;
}

/*
    A TagTuple represents a single possible set of tags that the arguments to
    `matchImpl` could have at runtime.

    Because D does not allow a struct to be the controlling expression
    of a switch statement, we cannot dispatch on the TagTuple directly.
    Instead, we must map each TagTuple to a unique integer and generate
    a case label for each of those integers.

    This mapping is implemented in `fromCaseId` and `toCaseId`. It uses
    the same technique that's used to map index tuples to memory offsets
    in a multidimensional static array.

    For example, when `args` consists of two SumTypes with two member
    types each, the TagTuples corresponding to each case label are:

    case 0:  TagTuple([0, 0])
    case 1:  TagTuple([1, 0])
    case 2:  TagTuple([0, 1])
    case 3:  TagTuple([1, 1])

    When there is only one argument, the caseId is equal to that
    argument's tag.
*/
struct TagTuple(typeCounts...) {
    size_t[typeCounts.length] tags;
    alias tags this;
    
    alias stride(size_t) = .stride(i, typeCounts);
    invariant {
        static foreach(i; 0..tags.length)
            assert(tags[i] < typeCounts[i], "Invalid tag");
    }

    this(SumTypes...)(ref const SumTypes args)
    if (allSatisfy!(isSumType, SumTypes) && args.length == typeCounts.length) {
        static foreach (i; 0..tags.length)
            tags[i] = args[i].tag;
    }
    
    static TagTuple fromCaseId(size_t caseId) {
        TagTuple result;

        // Most-significant to least-significant
        static foreach_reverse (i; 0..result.length) {
            result[i] = caseId / stride!i;
            caseId %= stride!i;
        }

        return result;
    }

    size_t toCaseId() {
        size_t result;
        static foreach (i; 0..tags.length)
            result += tags[i] * stride!i;

        return result;
    }
}

// Gets the count of types within a sumtype, for use with staticMap.
enum countSumType(T) = T.Types.length;

size_t stride(size_t dim, lengths...)() {
    import core.checkedint : mulu;

    size_t result = 1;
    bool overflow = false;
    static foreach(i; 0 .. dim) {
        result = mulu(result, lengths[i], overflow);
    }

    assert(!overflow, "Integer overflow");
    return result;
}

template handlerArgs(size_t dim, typeCounts...) {
    import std.format : format;

    enum tags = TagTuple!typeCounts.fromCaseId(caseId);
    alias handlerArgs = AliasSeq!();

    static foreach(i; 0..tags.length) {
        handlerArgs = AliasSeq!(
            handlerArgs,
            "args[%s].getByIndex!(&s)()".format(i, tags[i])
        );
    }
}

template matchImpl(bool try_, handlers...) {
    bool canFind(T)(T[] haystack, T needle) @nogc {
        foreach(ref item; haystack)
            if (item == needle)
                return true;

        return false;
    }

    auto ref matchImpl(SumTypes...)(auto ref SumTypes args)
    if (allSatisfy!(isSumType, SumTypes) && args.length > 0) {
        import std.format : format;

        // Generate dispatch.
        static if (args.length == 1) {

            // Single dispatch
            enum handlerArgs(size_t caseId) = "args[0].getByIndex!(%s)()".format(caseId);
            enum numCases = SumTypes[0].AllowedTypes.length;
            alias valueTypes(size_t caseId) = typeof(args[0].getByIndex!(caseId)());
        } else {

            // Multi-dispatch
            alias typeCount = staticMap!(countSumType, SumTypes);
            alias stride(size_t i) = .stride!(i, typeCount);
            alias TagTuple = .TagTuple!typeCount;
            alias handlerArgs(size_t caseId) = .handlerArgs!(caseId, typeCount);

            template valueTypes(size_t caseId) {
                enum tags = TagTuple.fromCaseId(caseId);
                alias getType(size_t i) = typeof(args[i].getByIndex!(tags[i])());
                alias valueTypes = staticMap!(getType, iota!(tags.length));
            }

            enum numCases = stride!(SumTypes.length);
        }

        // No-match ID.
        enum noMatch = size_t.max;

        // Static array that maps case IDs to handler IDs.
        enum matches = () {
            size_t[numCases] result;
            foreach(ref match; result) {
                match = noMatch;
            }

            static foreach(caseId; 0..numCases) {
                static foreach(handlerId, handler; handlers) {
                    static if (canMatch!(handler, valueTypes!caseId)) {
                        if (result[caseId] == noMatch)
                            result[caseId] = handlerId;
                    }
                }
            }

            return result;
        }();

        static foreach(handlerId, handler; handlers) {
            static assert(canFind(matches[], handlerId), "Handler "~typeof(handler).stringof~" never matches.");
        }

        enum handlerName(size_t hid) = "handler%s".format(hid);
        static foreach(size_t hid, handler; handlers) {
            mixin("alias ", handlerName!hid, " = handler;");
        }

        static if (args.length == 1)
            immutable argsId = args[0].tag;
        else
            immutable argsId = TagTuple(args).toCaseId;
        
        final switch(argsId) {
            static foreach(caseId; 0..numCases) {
                case caseId:
                    static if (matches[caseId] != noMatch)
                        return mixin(handlerName!(matches[caseId]), "(", handlerArgs!caseId, ")");
                    else {
                        static if (!try_) {
                            static assert(false, "No matching handler for types `"~valueTypes!(caseId).stringof~"`!");
                        }
                    } 
            }
        }

        assert(false, "unreachable");
    }
}

void destroyIfOwner(T)(ref T value) {
    nogc_delete(value);
}
