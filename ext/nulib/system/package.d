/**
    System Interop

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.system;
import numem.core.types;
import numem;

// NOTE:    This file is implemented as a package, this allows extension modules 
//          to use the nulib.system module, so don't try to simplify this into a
//          single file!

/**
    Opaque Handle
*/
alias Handle = OpaqueHandle!("Handle");
