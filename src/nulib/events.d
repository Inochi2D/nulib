module nulib.events;
import nulib.collections.vector;
import nulib.collections.map;
import numem.core.traits;
import numem.core.lifetime;
import numem.object;

/**
    A type for an event.
*/
alias Event(SenderType, ArgTypes...) = void function(SenderType, ArgTypes) @nogc;

/**
    Gets whether the given type is an event callback function.
*/
enum isEvent(T) = is(T : void function(SenderType, ArgTypes) @nogc, SenderType, ArgTypes...);

/**
    Gets the sender type of an event type $(D T).
*/
template EventSenderType(T) {
    static if (is(T : void function(SenderType, ArgTypes), SenderType, ArgTypes...))
        alias EventSenderType = SenderType;
    else
        alias EventSenderType = void;
}

/**
    Gets the argument types of an event type $(D T).
*/
template EventArgs(T) {
    static if (is(T : void function(SenderType, ArgTypes), SenderType, ArgTypes...))
        alias EventArgs = ArgTypes;
    else
        alias EventArgs = void;
}

/**
    An event handler which stores events internally.
*/
struct EventHandler(EventT)
if (isEvent!EventT) {
private:
@nogc:
    vector!EventT events_;

public:

    /**
        The callbacks registered with the handler.
    */
    @property EventT[] callbacks() => events_[];

    /**
        Type of the accepted event callback functions.
    */
    alias EventType = EventT;

    /**
        The type of accepted event senders.
    */
    alias SenderType = EventSenderType!EventT;

    /**
        The type of accepted event arguments.
    */
    alias ArgTypes = EventArgs!EventT;

    /**
        Adds an event to the handler.
    */
    void opOpAssign(string op)(EventT event)
    if (op == "~") {
        events_ ~= event;
    }

    /**
        Adds an event to the handler.
    */
    void opOpAssign(string op)(EventT event)
    if (op == "-") {
        events_.remove(event);
    }

    /**
        Calls all the events in the handler.
    */
    void opCall(SenderType sender, ArgTypes args) {
        foreach(event; events_) {
            event(sender, args);
        }
    }
}

@("EventHandler")
unittest {
    __gshared int vx;

    EventHandler!(Event!(void*, int)) handler;
    handler ~= (void* sender, int v) {
        vx += v;
    };

    handler(null, 42);
    assert(vx == 42);
}