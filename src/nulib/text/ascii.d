/**
    ASCII Helpers
    
    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.text.ascii;

@nogc nothrow:

/**
    Gets whether the character is ascii
*/
bool isASCII(char c) {
    return c < 128;
}

/**
    Gets whether the character is a hexidedcimal digit
*/
bool isHex(char c) {
    return 
        (c >= 'a' && c <= 'f') || 
        (c >= 'A' && c <= 'F') || 
        (c >= '0' && c <= '9');
}

/**
    Gets whether the given character is uppercase.
*/
bool isUpper(char c) {
    return (c >= 'A' && c <= 'Z');
}

/**
    Gets whether the given character is lowercase.
*/
bool isLower(char c) {
    return (c >= 'a' && c <= 'z');
}

/**
    Gets whether the character is numeric.
*/
bool isDigit(char c) {
    return (c >= '0' && c <= '9');
}

/**
    Gets whether the character is alphabetic.
*/
bool isAlpha(char c) {
    return 
        (c >= 'a' && c <= 'z') || 
        (c >= 'A' && c <= 'Z');
}

/**
    Gets whether the character is alpha-numeric.
*/
bool isAlphaNumeric(char c) {
    return 
        (c >= 'a' && c <= 'z') || 
        (c >= 'A' && c <= 'Z') || 
        (c >= '0' && c <= '9');
}

/**
    Gets whether the character is printable
*/
bool isPrintable(char c) {
    return (c >= 32 && c < 126);
}

/**
    Gets whether the character is an ASCII non-printable escape character
*/
bool isEscapeCharacter(char c) {
    return
        (c >= 0 && c <= 31) || 
        (c == 127);
}

/**
    Converts the given ascii character to lowercase.
*/
char toLower(char c) {
    if (isUpper(c))
        return cast(char)(c + 32);
    
    return c;
}

/**
    Converts the given ascii character to uppercase.
*/
char toUpper(char c) {
    if (isLower(c))
        return cast(char)(c - 32);
    
    return c;
}
