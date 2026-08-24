/**
    COM Base Interfaces

    Copyright: Copyright © 2023-2025, Kitsunebi Games
    Copyright: Copyright © 2023-2025, Inochi2D Project
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.com.unk;
import nulib.com.hresult;
import nulib.com.uuid;

/**
    Fundamental interface within the COM Programming Model.

    All COM classes must derive from this interface.
*/
@Guid!("00000000-0000-0000-C000-000000000046")
interface IUnknown {
extern(Windows) @nogc:
public:
    /**
        Helper type for getting the GUID of IUnknown.
    */
    extern(D) __gshared const IID iid = __uuidof!IUnknown;

    /**
        Queries a COM object for a pointer to one of its interface.

        Note:
            Because you pass the address of an interface pointer, 
            the method can overwrite that address with the pointer to the interface being queried for.
            Upon successful return, $(D *ppvObject) (the dereferenced address) contains a pointer to 
            the requested interface.
            If the object doesn't support the interface, the method sets $(D *ppvObject) 
            (the dereferenced address) to $(D null).

        Params:
            riid = Reference to the Guid of the interface being queried for.
            ppvObject = Reference to a pointer to store result of operation in.

        Returns:
            $(D S_OK) if supported, $(D E_NOINTERFACE) otherwise.
            If ppvObject is $(D null), returns $(D E_POINTER). 
    */
    HRESULT QueryInterface(const(IID)* riid, out void* ppvObject);
    
    /**
        A helper function that infers an interface identifier.
    */
    extern(D)
    HRESULT QueryInterface(T)(T** pvObject) if(is(__uuidof!T)) {
        return QueryInterface(__uuidof!T, pvObject);
    }

    /**
        Increments the reference count for an interface pointer to a COM object.

        You should call this method whenever you make a copy of an interface pointer.

        Returns:
            The new reference count, should only be used for debugging.
    */
    uint AddRef();
    
    /**
        Decrements the reference count for an interface on a COM object.

        Returns:
            The new reference count, should only be used for debugging.
    */
    uint Release();
}

alias LPUNKNOWN = IUnknown; /// Convenience alias.


/**
    Asynchronous version of IUnknown.

    Note:
        This interface is poorly documented by Microsoft, but you generally
        want a $(D ICallFactory) to actually do these calls.
    
    See_Also:
        $(LINK https://devblogs.microsoft.com/oldnewthing/20220214-44/?p=106251)
*/
@Guid!("000e0000-0000-0000-C000-000000000046")
interface AsyncIUnknown : IUnknown {
    
    /**
        Begins to query a COM object for a pointer to one of its interface.

        Params:
            riid = Reference to the Guid of the interface being queried for.

        Returns:
            An $(D HRESULT) status code.
    */
    HRESULT Begin_QueryInterface(ref IID riid);
    
    /**
        Finishes querying a COM object for a pointer to one of its interface.

        Note:
            Because you pass the address of an interface pointer, 
            the method can overwrite that address with the pointer to the interface being queried for.
            Upon successful return, $(D *ppvObject) (the dereferenced address) contains a pointer to 
            the requested interface.
            If the object doesn't support the interface, the method sets $(D *ppvObject) 
            (the dereferenced address) to $(D null).

        Params:
            ppvObject = Reference to a pointer to store result of operation in.

        Returns:
            An $(D HRESULT) status code.
    */
    HRESULT Finish_QueryInterface(out void* ppvObject);
    
    /**
        Begins incrementing the reference count for an interface pointer to a COM object.

        You should call this method whenever you make a copy of an interface pointer.

        Returns:
            An $(D HRESULT) status code.
    */
    HRESULT Begin_AddRef();
    
    /**
        Finishes incrementing the reference count for an interface pointer to a COM object.

        You should call this method whenever you make a copy of an interface pointer.

        Returns:
            The new reference count, should only be used for debugging.
    */
    uint Finish_AddRef();
    
    /**
        Begins decrementing the reference count for an interface on a COM object.

        Returns:
            An $(D HRESULT) status code.
    */
    HRESULT Begin_Release();
    
    /**
        Finishes decrementing the reference count for an interface on a COM object.

        Returns:
            The new reference count, should only be used for debugging.
    */
    uint Finish_Release();
}

alias LPASYNCUNKNOWN = AsyncIUnknown; /// Convenience alias.

/**
    A class factory.

    Class factories allows classes to be instantiated in an uninitialized state.
*/
interface IClassFactory : IUnknown {
extern(Windows) @nogc:
    
    /**
        Creates an uninitialized object.

        Params:
            outer =     If the object is an aggregate, specify controlling $(D IUnknown) 
                        interface, otherwise set this to $(D null)
            riid =      The identifier of the interface to be used to communicate with
                        the newly created object. If $(D outer) is $(D null), this must
                        be set to $(D IUnknown.IID).
            ppvObject = The address of pointer variable that receives the interface 
                        pointer requested in $(D riid).

        Returns:
            $(D S_OK) if creation succeeded, 
            $(D CLASS_E_NOAGGREGATION) if object doesn't support aggregation, 
            $(D E_NOINTERFACE) if the $(D riid) interface isn't supported,
            or either of $(D E_INVALIDARG), $(D E_OUTOFMEMORY) and $(D E_UNEXPECTED).
    */
    HRESULT CreateInstance(IUnknown outer, const(IID)* riid, out void* ppvObject);
    alias RemoteCreateInstance = CreateInstance;

    /**
        Locks an object application open in memory. 
        This enables instances to be created more quickly.
    
        Params:
            fLock = If $(D true) increments lock count, otherwise the lock count
                    is decremented.
        
        Returns:
            Either of $(D S_OK), $(D E_FAIL), $(D E_UNEXPECTED) or $(D E_OUTOFMEMORY)
    */
    HRESULT LockServer(bool fLock);
    alias RemoteLockServer = LockServer;
}

alias LPCLASSFACTORY = IClassFactory; /// Convenience alias.
