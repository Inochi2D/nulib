/**
    Path buffers

    Contains helpers for constructing paths in a type-safe way.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.uri;
import nulib.collections;
import nulib.string;
import nulib.text.ascii;
import numem;

/**
    The path seperator of the system.
*/
version(Windows) enum NU_PATHSEP = '\\';
else enum NU_PATHSEP = '/';

/**
    PathBufs allows for type-safe path passing to 
    nulib APIs.
*/
struct URI {
@nogc nothrow:
private:
    nstring store;

    // Slices into store
    string scheme_;
    string authority_;
    string path_;
    string query_;
    string fragment_;

    void parse(string url) {
        store.clear();

        // Local paths.
        if (isLocalPath(url)) {
            store = nstring(url);
            path_ = store;
            return;
        }
    }

    bool isPathSep(char c) {
        return c == '/' || c == NU_PATHSEP;
    }

    bool isLocalPath(string path) {

        //  NOTE:   The Windows/DOS path scheme uses a drive letter as a scheme,
        //          followed by any of the path seperators.
        version(Windows) {
            if (path.length >= 3) {
                return 
                    isAlpha(path[0]) &&
                    path[1] == ':' && 
                    isPathSep(path[2]);
            }

            //  NOTE: Windows denotes SMB shares with \\, these are NOT local.
            if (path.length > 2) {
                if (path[0..2] == "\\\\")
                    return false;
            }
        }

        size_t i;
        while (i++ < path.length) {
            char c = path[i];

            if (c == ':' && i > 1)
                return false;

            if (c == NU_PATHSEP)
                return true;
        }

        return false;
    }
public:
    @disable this();

    ~this() {
        store.clear();
    }

    /**
        Creates a URI from a string.
    */
    this(string url) {
        this.parse(url);
    }

    /**
        Copy constructor.
    */
    this(ref typeof(this) rhs) {
        this.store = rhs.store;
    }

    /**
        Whether the URI refers to a local path.
    */
    @property bool isLocal() {
        return
            scheme_.length == 0 && 
            authority_.length == 0 && 
            path_.length > 0;
    }

    /**
        Gets the path portion of the URI
    */
    @property string path() { return path_; }
}
