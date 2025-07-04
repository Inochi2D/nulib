/**
    POSIX Implementation for nulib.system.mod

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.priv.mod;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;
else version (VisionOS)
    version = Darwin;

version(Posix):

import numem;

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

private extern (C):

/**/
export
bool _nu_module_utf16_paths() @nogc nothrow {
    return false;
}

/*
    Function which loads a module from the given path.

    This is implemented by backends to abstract away the OS intricaices
    of loading modules and finding symbols within.
*/
export
void* _nu_module_open(void* path) @nogc nothrow {
    version(Darwin) {
        if (path is null)
            path = cast(void*)_dyld_get_image_name(0);
    }

    void* handle = dlopen(cast(const(char)*)path, 0);
    return handle;
}

/*
    Function which loads a module from the given path.

    This is implemented by backends to abstract away the OS intricaices
    of loading modules and finding symbols within.
*/
export
void _nu_module_close(void* module_) @nogc nothrow {
    cast(void) dlclose(module_);
}

/*
    Function which finds a symbol within a given module

    This is implemented by backends to abstract away the OS intricaices
    of loading modules and finding symbols within.
*/
export
void* _nu_module_get_symbol(void* module_, const(char)* symbol) @nogc nothrow {
    return dlsym(module_, symbol);
}

/*
    Function which gets the "base address" of the module.

    This is backend implementation defined; but is what should allow
    $(D _nu_module_enumerate_sections) and $(D _nu_module_enumerate_symbols)
    to function.
*/
export
void* _nu_module_get_base_address(void* module_) @nogc nothrow {
    version(Darwin) {
        foreach(i; 0.._dyld_image_count()) {

            // Find the image.
            const(char)* imageName = _dyld_get_image_name(i);
            void* imageHandle = dlopen(imageName, 0);
            cast(void)dlclose(imageHandle);

            if (module_ == imageHandle) {
                return nogc_new!mach_image(
                    cast(mach_header_64*)_dyld_get_image_header(i),
                    _dyld_get_image_vmaddr_slide(i)
                );
            }
        }
        return null;
    } else {

        Dl_info info;
        if (dladdr(module_, info) != 0)
            return info.dli_fbase;

        return null;
    }
}

export
void _nu_module_release_base_address(void* module_) @nogc nothrow {
    version(Darwin) {
        if (module_)
            nu_free(cast(mach_image*)module_);
    }
}

export
SectionInfo[] _nu_module_enumerate_sections(void* base) @nogc nothrow {
    version(Darwin) {
        mach_image* image = cast(mach_image*)base;
        if (!_nu_module_darwin_get_is_supported(image))
            return null;
        
        uint symtabCount;
        SectionInfo[] allSections;
        load_command* lcmd = _nu_module_get_first_command(image);
        foreach(i; 0..image.header.ncmds) {

            SectionInfo[] sections;
            if (lcmd.cmd == LC_SEGMENT) {

                segment_command_32* segcmd = cast(segment_command_32*)(cast(void*)lcmd);
                sections = sections.nu_resize(segcmd.nsects);
                section_32* sect = cast(section_32*)(cast(void*)lcmd+segment_command_32.sizeof);
                foreach(j; 0..segcmd.nsects) {

                    sections[j].segment = _nu_module_darwin_get_name(sect.segname);
                    sections[j].section = _nu_module_darwin_get_name(sect.sectname);
                    sections[j].start = cast(void*)sect.addr+image.vmaddrSlide;
                    sections[j].end = cast(void*)sect.addr+image.vmaddrSlide+sect.size;

                    // Next section.
                    sect++;
                }

                allSections = _nu_module_darwin_combine_sect_infos(allSections, sections);
            } else if (lcmd.cmd == LC_SEGMENT_64) {
                
                segment_command_64* segcmd = cast(segment_command_64*)(cast(void*)lcmd);
                sections = sections.nu_resize(segcmd.nsects);
                section_64* sect = cast(section_64*)(cast(void*)lcmd+segment_command_64.sizeof);
                foreach(j; 0..segcmd.nsects) {

                    sections[j].segment = _nu_module_darwin_get_name(sect.segname);
                    sections[j].section = _nu_module_darwin_get_name(sect.sectname);
                    sections[j].start = cast(void*)sect.addr+image.vmaddrSlide;
                    sections[j].end = cast(void*)sect.addr+image.vmaddrSlide+sect.size;

                    // Next section.
                    sect++;
                }
                
                allSections = _nu_module_darwin_combine_sect_infos(allSections, sections);
            }

            if (lcmd.cmd == LC_SYMTAB)
                symtabCount++;

            lcmd = _nu_module_darwin_next_command(lcmd);
        }

        return allSections;
    } else {
        return null;
    }
}

export
Symbol[] _nu_module_enumerate_symbols(void* base) @nogc nothrow {
    version(Darwin) {
        mach_image* image = cast(mach_image*)base;
        if (!_nu_module_darwin_get_is_supported(image))
            return null;

        // MH_DYLIB_IN_CACHE
        if (image.header.flags & 0x80000000)
            return null;

        // Locate nlists
        symtab_command* symcmd = cast(symtab_command*)_nu_module_darwin_find_command(image, LC_SYMTAB);
        if (!symcmd)
            return null;
        
        const(char)* strtab = cast(const(char)*)(base + image.vmaddrSlide + symcmd.stroff);
        nlist[]      symtab = (cast(nlist*)(base + symcmd.symoff))[0..symcmd.nsyms];

        // Fill out symbols.
        size_t nlen = 0;
        Symbol[] allSymbols;
        allSymbols = allSymbols.nu_resize(symcmd.nsyms);
        foreach(j; 0..symcmd.nsyms) {
            nlist nl = symtab[j];
            if (nl.n_strx == 0)
                continue;
            
            // Externally defined.
            if (nl.n_type & 0x01)
                continue;

            void* addr = base+nl.n_value;
            ubyte typeFlag = nl.n_type & 0x0e;

            // No symbol
            if (typeFlag == 0x00)
                addr = null;
            
            // Absolute symbol.
            if (typeFlag == 0x02)
                addr = cast(void*)nl.n_value;
            
            // TODO: Implement indirect symbols.
            if (typeFlag == 0xa0)
                addr = null;

            allSymbols[nlen++] = Symbol(_nu_strz(strtab+nl.n_strx), addr);
        }

        // If we found no symbols just empty the list.
        if (nlen == 0) {
            allSymbols = allSymbols.nu_resize(0);
            return null;
        }
        return allSymbols[0..nlen];
    } else {
        return null;
    }
}





//
//          SYSTEM SPECIFIC HELPERS
//

version(Darwin) {
    string _nu_module_darwin_get_name(ref char[16] name) @nogc nothrow {
        foreach(i; 0..name.length) {
            if (name[i] == '\0')
                return cast(string)name[0..i];
        }
        return cast(string)name;
    }

    SectionInfo[] _nu_module_darwin_combine_sect_infos(SectionInfo[] a, SectionInfo[] b) @nogc nothrow {
        if (!a && b) return b;
	if (a && !b) return a;        

        SectionInfo[] c;
        c = c.nu_resize(a.length+b.length);
        c[0..a.length]   = a[0..$];
        c[$-b.length..$] = b[0..$];
        
        a = a.nu_resize(0);
        b = b.nu_resize(0);
        return c;
    }

    /**
        Gets whether the given image is valid
    */
    bool _nu_module_darwin_get_is_supported(mach_image* image) @nogc nothrow {
        return image !is null && (
            image.header.magic == MH_MAGIC || 
            image.header.magic == MH_MAGIC_64
        );
    }

    /*
        Gets the first load command
    */
    load_command* _nu_module_get_first_command(mach_image* image) @nogc nothrow {
        return cast(load_command*)(
            image.header.magic == MH_MAGIC ?
                (cast(void*)image.header)+mach_header_32.sizeof :
                (cast(void*)image.header)+mach_header_64.sizeof
        );
    }

    /*
        Gets the load command with the requested name.
    */
    load_command* _nu_module_darwin_find_command(mach_image* image, uint magic) @nogc nothrow {
        load_command* cmd = _nu_module_get_first_command(image);
        foreach(i; 0..image.header.ncmds) {
            if (cmd.cmd == magic)
                return cmd;

            cmd = _nu_module_darwin_next_command(cmd);
        }
        return null;
    }

    /*
        Gets the next command.
    */
    pragma(inline, true)
    load_command* _nu_module_darwin_next_command(load_command* cmd) @nogc nothrow {
        return cast(load_command*)((cast(void*)cmd)+cmd.cmdsize);
    }

    Symbol[] _nu_module_darwin_combine_syms(Symbol[] a, Symbol[] b) @nogc nothrow {
        if (!a && b) return b;
	if (a && !b) return a;        

        Symbol[] c;
        c = c.nu_resize(a.length+b.length);
        c[0..a.length]   = a[0..$];
        c[$-b.length..$] = b[0..$];
        
        a = a.nu_resize(0);
        b = b.nu_resize(0);
        return c;
    }
    
} else {
    
}


//
//          HELPERS
//

extern(D)
string _nu_strz(const(char)* str) @nogc nothrow {
    size_t i = 0;
    while(str[i] != '\0') i++;
    return cast(string)str[0..i];
}


//
//          LOCAL BINDINGS
//

extern(C) extern void* dlopen(const(char)*, int) @nogc nothrow;
extern(C) extern void* dlsym(void*, const(char)*) @nogc nothrow;
extern(C) extern int dladdr(const(void)*, ref Dl_info) @nogc nothrow;
extern(C) extern int dlclose(void*) @nogc nothrow;

struct Dl_info {
    const(char)* dli_fname;
    void* dli_fbase;
    const(char)* dli_sname;
    void* dli_saddr;
}

version(Darwin) {
    extern(C) extern int _dyld_image_count() @nogc nothrow;
    extern(C) extern void* _dyld_get_image_header(uint) @nogc nothrow;
    extern(C) extern const(char)* _dyld_get_image_name(uint) @nogc nothrow;
    extern(C) extern ptrdiff_t _dyld_get_image_vmaddr_slide(uint) @nogc nothrow;

    enum uint
        MH_MAGIC_64 = 0xfeedfacf,
        MH_MAGIC = 0xfeedface;
    
    enum uint
        LC_SYMTAB = 0x2,
        LC_SEGMENT = 0x1,
        LC_SEGMENT_64 = 0x19;

    struct mach_image {
        mach_header_64* header;
        ptrdiff_t vmaddrSlide;
    }

    struct mach_header_32 {
        uint magic;
        int cputype;
        int cpusubtype;
        uint filetype;
        uint ncmds;
        uint sizeofcmds;
        uint flags;
    }

    struct mach_header_64 {
        uint magic;
        int cputype;
        int cpusubtype;
        uint filetype;
        uint ncmds;
        uint sizeofcmds;
        uint flags;
        uint reserved;
    }

    struct load_command {
        uint cmd;
        uint cmdsize;
    }

    struct segment_command_32 {
        uint cmd;
        uint cmdsize;
        char[16] segname = 0;
        uint vmaddr;
        uint vmsize;
        uint fileoff;
        uint filesize;
        int maxprot;
        int initprot;
        uint nsects;
        uint flags;
    }

    struct segment_command_64 {
        uint cmd;
        uint cmdsize;
        char[16] segname = 0;
        ulong vmaddr;
        ulong vmsize;
        ulong fileoff;
        ulong filesize;
        int maxprot;
        int initprot;
        uint nsects;
        uint flags;
    }

    struct section_32 {
        char[16] sectname = 0;
        char[16] segname = 0;
        uint addr;
        uint size;
        uint offset;
        uint align_;
        uint reloff;
        uint nreloc;
        uint flags;
        uint reserved1;
        uint reserved2;
    }

    struct section_64 {
        char[16] sectname = 0;
        char[16] segname = 0;
        ulong addr;
        ulong size;
        uint offset;
        uint align_;
        uint reloff;
        uint nreloc;
        uint flags;
        uint reserved1;
        uint reserved2;
        uint reserved3;
    }

    struct nlist {
        uint n_strx;
        ubyte n_type;
        ubyte n_sect;
        ushort n_desc;
        size_t n_value;
    }

    struct symtab_command {
        uint cmd;
        uint cmdsize;
        uint symoff;
        uint nsyms;
        uint stroff;
        uint strsize;
    }
}
