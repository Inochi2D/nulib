/**
    Shared Library Modules

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.system.mod;
import nulib.collections.vector;
import nulib.system;
import nulib.string;
import numem;

/**
    A higher level wrapper over OS level modules/shared libraries.

    The module is lazy-loading, meaning segment and symbol lists
    will only be enumerated when requested; this in turn means
    modules can be relatively lightweight.
*/
class Module : NuRefCounted {
private:
@nogc:
    __gshared Module _self;
    Handle handle;

    void* baseaddr;
    SectionInfo[] sections_;
    Symbol[] symbols_;

    // Cleanup function.
    void cleanup() {
        this.sections_ = sections_.nu_resize(0);
        this.symbols_ = symbols_.nu_resize(0);
    }

    // Converts UTF8 path to a native path.
    void* getNativePath(string path) {
        if (!path)
            return null;

        if (_nu_module_utf16_paths()) {
            
            nwstring tmp = path;
            const(wchar)[] utf16 = tmp.ptr[0..tmp.realLength].nu_dup();
            return cast(void*)utf16.ptr;
        }

        nstring tmp = path;
        const(char)[] utf8 = tmp.ptr[0..tmp.realLength].nu_dup();
        return cast(void*)utf8.ptr;
    }

public:

    /**
        List of all sections in the module.
    */
    final
    @property SectionInfo[] sections() {
        if (!baseaddr)
            return null;
        
        if (!sections_)
            this.sections_ = _nu_module_enumerate_sections(baseaddr);
        return sections_;
    }

    /**
        List of all exported symbols in the module.
    */
    final
    @property Symbol[] symbols() {
        if (!baseaddr)
            return null;
        
        if (!this.symbols_)
            this.symbols_ = _nu_module_enumerate_symbols(baseaddr);
        return symbols_; 
    }

    /**
        The base address the module is loaded into.
    */
    final
    @property void* baseAddress() {
        return baseaddr;
    }

    /**
        Gets the calling module.
    */
    static @property Module self() {
        if (!_self)
            _self = nogc_new!Module(null);
        
        return _self;
    }

    /**
        Loads a module from the given path.

        This function has more "smarts" than the constructor, and will
        transform the incoming path to find the library in question.

        This includes things like looking up macOS bundles, and the like.

        Params:
            pathOrName = Path to; or name of the module to load.
        
        Returns:
            A new module, or $(D null) if the module failed to load.
    */
    static Module load(string pathOrName) {
        if (!pathOrName)
            return null;

        Module mod = nogc_new!Module(_nu_module_transform_path(pathOrName));
        if (mod.handle is null) {
            mod.release();
            return null;
        }

        return mod;
    }

    /**
        Loads a module from a path into this application's address space,
        without doing any path transformations.

        It is recommended to use $(D Module.load) instead of this.

        Params:
            path = Path to a module.
    */
    this(string path) {
        void* rpath = getNativePath(path);
        this.handle = cast(Handle)_nu_module_open(rpath);
        this.baseaddr = _nu_module_get_base_address(handle);
        
        if (rpath) nu_free(rpath);
    }

    /**
        Destructor
    */
    ~this() {
        this.cleanup();
        _nu_module_release_base_address(handle);
        _nu_module_close(handle);
    }
    
    /**
        Gets a symbol from the module.

        Params:
            sym = The name of the symbol to get.
        
        Returns:
            A pointer to the symbol or $(D null) if the
            symbol was not found.
    */
    final
    void* getSymbol(string sym) {
        nstring psym = sym;
        return _nu_module_get_symbol(handle, psym.ptr);
    }

    /**
        Lists all symbols within the given section.

        Params:
            section = The section to query.
        
        Returns:
            A weak vector containing the symbols within the given
            section's memory space..
    */
    weak_vector!Symbol createSymbolListFor(SectionInfo section) {
        weak_vector!Symbol rsymbols;

        Symbol[] syms = symbols;
        foreach(i; 0..syms.length) 
            if (syms[i].ptr >= section.start && syms[i].ptr <= section.end)
                rsymbols ~= syms[i];
        
        return rsymbols;
    }

    /**
        Finds a section within the module, and optionally limits the
        search to be within a specific segment, if applicable.

        Params:
            section = The section to find
            segment = The segment to find it in, or $(D null).
        
        Returns:
            A reference to a section info object describing the section, 
            owned by the module, or $(D null) if not found.
    */
    final
    SectionInfo* findSection(string section, string segment = null) {
        SectionInfo[] sects = sections;
        foreach(i; 0..sects.length) {
            if (sects[i].section == section) {
                if (segment && sects[i].segment != segment)
                    continue;
                
                return &sects[i];
            }
        }
        
        return null;
    }

    /**
        Gets the section which a symbol belongs to.

        Params:
            sym = Pointer to a symbol in the module, as returned by $(D getSymbol).
        
        Returns:
            A reference to a section info object describing the section, 
            owned by the module, or $(D null) if not found.
    */
    final
    SectionInfo* getSymbolSection(void* sym) {
        SectionInfo[] sects = sections;
        foreach(i; 0..sects.length) 
            if (sym >= sects[i].start && sym <= sects[i].end)
                return &sects[i];

        // Not found.
        return null;
    }
}

/**
    A symbol within a section.
*/
struct Symbol {
@nogc:

    /**
        Name of the symbol
    */
    string name;
    
    /**
        Pointer to the symbol
    */
    void* ptr;
}

/**
    Information about sections.
*/
struct SectionInfo {
@nogc:
    
    /**
        Segment of the section, if applicable.
    */
    string segment;

    /**
        Name of the section
    */
    string section;

    /**
        Start address of the section
    */
    void* start;

    /**
        End address of the section
    */
    void* end;
}

//
//          FOR IMPLEMENTORS
//

private extern(C):
import core.attribute : weak;

/*
    Optional helper function for platforms which have special kinds of "Modules",
    eg. Framework Bundles on macOS.

    See: https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/Concepts/FrameworkAnatomy.html
*/
string _nu_module_transform_path(string path) @weak @nogc nothrow {
    return path;
}

/**
    Optional helper that defines whether paths are in UTF-16 format.
*/
bool _nu_module_utf16_paths() @weak @nogc nothrow {
    return false;
}

/*
    Function which loads a module from the given path.

    This is implemented by backends to abstract away the OS intricaices
    of loading modules and finding symbols within.
*/
void* _nu_module_open(void* path) @weak @nogc nothrow {
    return null;
}

/*
    Function which loads a module from the given path.

    This is implemented by backends to abstract away the OS intricaices
    of loading modules and finding symbols within.
*/
void _nu_module_close(void* module_) @weak @nogc nothrow {
    return;
}

/*
    Function which finds a symbol within a given module

    This is implemented by backends to abstract away the OS intricaices
    of loading modules and finding symbols within.
*/
void* _nu_module_get_symbol(void* module_, const(char)* symbol) @weak @nogc nothrow {
    return null;
}

/*
    Function which gets the "base address" of the module.

    This is backend implementation defined; but is what should allow
    $(D _nu_module_enumerate_sections) and $(D _nu_module_enumerate_symbols)
    to function.
*/
void* _nu_module_get_base_address(void* module_) @weak @nogc nothrow {
    return null;
}

/*
    Function which releases the "base address" of the module.

    This is backend implementation defined; but is what should allow
    $(D _nu_module_enumerate_sections) and $(D _nu_module_enumerate_symbols)
    to function.
*/
void _nu_module_release_base_address(void* module_) @weak @nogc nothrow {
    return;
}

/*
    Function which enumerates all of the sections within a module.
*/
SectionInfo[] _nu_module_enumerate_sections(void* base) @weak @nogc nothrow {
    return null;
}

/*
    Function which enumerates all of the exported symbols.
*/
Symbol[] _nu_module_enumerate_symbols(void* base) @weak @nogc nothrow {
    return null;
}
