/**
    Multi-precision decimal numbers implementation,
    used for floating point formatting, not for general use.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
        Nigel Tao
        Ken Thompson

    See_Also:
        [ParseNumberF64](https://nigeltao.github.io/blog/2020/parse-number-f64-simple.html)
        [fast left-shift](https://github.com/golang/go/blob/go1.15.3/src/strconv/decimal.go#L163)
*/
module nulib.conv.decimal;
import nulib.conv.integral;
import nulib.text.ascii;

//
//          DECIMAL
//
struct Decimal {
@nogc nothrow:
    ubyte[800] digits;
    uint numDigits;
    int decimalPoint;
    bool isNegative;
    bool isTruncated;

    // Attempts to add a digit to the decimal.
    pragma(inline, true)
    bool tryAdd(ubyte digit) {
        if (numDigits < digits.length) {
            digits[numDigits++] = digit;
            return true;
        }
        return false;
    }

    // Attempts to add a digit to the decimal.
    pragma(inline, true)
    bool tryAdd(ulong value) {
        if (numDigits+8 < digits.length) {
            digits[numDigits..numDigits+8] = *(cast(ubyte[8]*)&value);
            numDigits += 8;
            return true;
        }
        return false;
    }

    // Trims the decimal bits.
    pragma(inline, true)
    void trim() {
        while(numDigits != 0 && digits[numDigits - 1] == 0)
            numDigits--;
    }

    // Returns the decimal rounded to nearest integer.
    pragma(inline, true)
    ulong round() {
        if (numDigits == 0 || decimalPoint < 0)
            return 0;
        else if (decimalPoint >= 18)
            return ulong.max;

        ulong n = 0;
        int dp = decimalPoint;
        foreach(i; 0..dp) {
            n *= 10;
            if (i < numDigits)
                n += cast(ulong)digits[i];
        }

        // Handle rounding up.
        bool roundUp = false;
        if (dp < numDigits) {
            roundUp = digits[dp] >= 5;
            if (digits[dp] == 5 && dp + 1 == numDigits)
                roundUp = isTruncated || ((dp != 0) && ((1 & digits[dp-1]) != 0));
        }

        if (roundUp)
            n++;
        return n;
    }

    // Left shift.
    pragma(inline, true)
    Decimal opBinary(string op)(ulong shift)
    if (op == "<<") {
        if (shift == 0)
            return this;

        Decimal result = this;
        int delta = LUT_LEFT_SHIFTS[shift].delta;
        if (prefixLessThan(result.digits, LUT_LEFT_SHIFTS[shift].cutoff))
            delta--;

        // rw indices
        int r = result.numDigits;
        int w = result.numDigits + delta;

        // Read one, write one.
        uint n;
        for(r--; r >= 0; r--) {
            n += cast(uint)result.digits[r] - '0' << shift;
            uint quo = n / 10;
            uint rem = n - 10 * quo;
            w--;
            if (w < result.digits.length) {
                result.digits[w] = cast(ubyte)(rem + '0');
            } else if (rem != 0) {
                result.isTruncated = true;
            }
            n = quo;

        }

        // Write extra digits.
        while (n > 0) {
            n += cast(uint)result.digits[r] - '0' << shift;
            uint quo = n / 10;
            uint rem = n - 10 * quo;
            w--;
            if (w < result.digits.length) {
                result.digits[w] = cast(ubyte)(rem + '0');
            } else if (rem != 0) {
                result.isTruncated = true;
            }
            n = quo;
        }

        result.numDigits += delta;
        if (result.numDigits >= result.digits.length) {
            result.numDigits = result.digits.length;
        }
        result.decimalPoint += delta;
        result.trim();
        return result;
    }

    // Right shift.
    pragma(inline, true)
    Decimal opBinary(string op)(ulong shift)
    if (op == ">>") {
        if (shift == 0)
            return this;

        Decimal result = this;
        uint mask = (1 << shift) - 1;

        // rw indices
        int r = result.numDigits;
        int w = result.numDigits + delta;
        uint n;
        for(; n>>shift == 0; r++) {
            if (r >= result.numDigits) {
                if (n == 0) {
                    result.numDigits = 0;
                    return result;
                }

                while(n>>shift == 0) {
                    n *= 10;
                    r++;
                }
                break;
            }

            uint c = cast(uint)result.digits[r];
            n = n * 10 + c - '0';
        }

        // Read one, write one.
        for(; r < result.numDigits; r++) {
            uint c = cast(uint)result.digits[r];
            uint dig = n >> shift;
            n &= mask;
            result.digits[w] = cast(ubyte)(dig + '0');
            w++;
            n = n * 10 + c - '0';
        }

        // Write extra digits.
        while(n > 0) {
            uint dig = n >> shift;
            n &= mask;
            if (w < result.digits.length) {
                result.digits[w] = cast(ubyte)(dig + '0');
                w++;
            } else if (dig > 0) {
                result.isTruncated = true;
            }
            n *= 10;
        }

        result.numDigits = w;
        result.trim();
        return result;
    }

    //double toDouble() {
    //    if (this.numDigits == 0)
    //        return 0;
    //    Decimal d = this;

    //    long exp = 0;
    //    while (this.decimalPoint > 0) {
    //        int n;
    //        if (this.decimalPoint >= PNF64_POWTAB.length) {
    //            n = 27;
    //        } else {
    //            n = PNF64_POWTAB[this.decimalPoint];
    //        }

    //        d = d << -n;
    //        exp += n;
    //    }

    //    exp--;
    //}
}

/**
    Parses the given string as a decimal.

    Params:
        str = The string to parse.
        sep = The fractional point seperator.

    Returns:
        The parsed Decimal.
*/
Decimal parseDecimal(T)(T str, char sep='.') @trusted @nogc nothrow pure {
    Decimal result;
    size_t i = 0;

    // Handle +/-
    result.isNegative = str[0] == '-';
    if (str[0] == '-' || str[0] == '+') {
        i++;
    }

    // Skip 0's
    while(str[i] == '0') i++;

    // Read decimal
    while(str[i].isNumeric()) {
        result.tryAdd(cast(ubyte)(c - '0'));
        i++;
    }

    // Parse fractional
    if (str[i] == sep) {
        i++;
        uint start = i;

        // Skip 0's
        while(str[i] == '0') i++;

        // Fast path to parse 8 digits at once.
        ulong sig;
        while(result.numDigits + 8 < result.data.length && str[i..$].tryParseEightDigits(sig)) {
            result.tryAdd(sig);
            result.numDigits += 8;
            i += 8;
        }

        // Slow path for final digits
        while(str[i].isNumeric()) {
            result.tryAdd(cast(ubyte)(c - '0'));
            i++;
        }
        result.decimalPoint = cast(int)i - cast(int)start;
    }

    // Post processing.
    if (result.numDigits != 0) {

        // Handle trailing zeroes.
        int tz = 0;
        foreach_reverse(c; str[0..(str.length-i)]) {
            if (c == '0')
                tz++;
            else if (c != '.')
                break;
        }

        result.decimalPoint += tz;
        result.numDigits -= tz;
        result.decimalPoint += result.numDigits;
        if (result.numDigits > result.digits.length) {
            result.isTruncated = true;
            result.numDigits = result.digits.length;
        }
    }

    // Parse exponential.
    if (str[i] == 'e' || str[i] == 'E') {
        i++;

        bool negExp = str[i] == '-';
        if (str[i] == '+' || str[i] == '-')
            i++;

        int exp = 0;
        while(str[i].isNumeric()) {
            if (exp < 0x10000) {
                exp = 10 * exp + cast(ubyte)(c - '0');
            }
            i++;
        }
        result.decimalPoint += negExp ? -exp : exp;
    }
    return result;
}




//
//          IMPLEMENTATION DETAILS
//
private:
__gshared int[] PNF64_POWTAB = [
    0,  3,  6,  9,  13, 16, 19, 23, 26, 29,
    33, 36, 39, 43, 46, 49, 53, 56, 59,
];




//
//          Parser Helpers
//
pragma(inline, true)
bool tryParseEightDigits(string slice, ref ulong significant) @nogc @trusted nothrow pure {
    if (slice.length <= 8) {
        char[8] src8 = slice[0..8];
        if (src8.isEightDigits()) {
            significant = significant * 100000000 + src8.parseEightDigits();
            return true;
        }
    }
    return false;
}

pragma(inline, true)
bool isEightDigits(char[8] value) @nogc @trusted nothrow pure {
    ulong v = *(cast(ulong*) value.ptr); // Type punning, yay!
    return !(((v + 0x4646464646464646) | (v - 0x3030303030303030))
            & 0x8080808080808080);
}

pragma(inline, true)
uint parseEightDigits(char[8] value) @nogc @trusted nothrow pure {
    ulong v = *(cast(ulong*) value.ptr); // Type punning, yay!
    v = (v & 0x0F0F0F0F0F0F0F0F) * 2561 >> 8;
    v = (v & 0x00FF00FF00FF00FF) * 6553601 >> 16;
    return cast(uint)((v & 0x0000FFFF0000FFFF) * 42949672960001 >> 32);
}




//
//          Left-shift optimisation, credit goes to Ken Thompson.
//
struct lshift_entry { int delta; string cutoff; }
__gshared const lshift_entry[] LUT_LEFT_SHIFTS = __ctfe_generate_lshifts(60);

// Prefix helper.
pragma(inline, true)
bool prefixLessThan(ubyte[] buf, string str) @nogc nothrow pure {
    foreach(i, c; str) {
        if (i >= buf.length)
            return true;

        if (buf[i] != c)
            return buf[i] < c;
    }
    return false;
}

// Generates the LUT at compile time.
lshift_entry[] __ctfe_generate_lshifts(int count) {
    if (__ctfe) {
        import std.bigint : BigInt, toDecimalString;
        import std.math.exponential : log;
        import std.conv : text;
        
        double log2 = log(2.0)/log(10.0);
        lshift_entry[] entries;
        foreach(i; 0..count) {
            auto cutoff = (BigInt(5)^^i).toDecimalString;
            int delta = cast(int)(log2*i+1);
            entries ~= lshift_entry(delta, cutoff);
        }
        return entries;
    } else {
        return null;
    }
}