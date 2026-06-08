/**
    NuLib fallback floating-point conversion.

    Multi-precision decimal numbers implementation,
    used for floating point formatting, not for general use.

    The "Decimal" type here does not support any math operations
    not useful

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:
        Luna Nielsen
        Ken Thompson (fast left-shift)

    See_Also:
        $(LINK2 https://github.com/golang/go/blob/go1.15.3/src/strconv/decimal.go#L163, Fast left-shift)
        $(LINK2 https://nigeltao.github.io/blog/2020/parse-number-f64-simple.html, ParseNumberF64 by Simple Decimal Conversion)
*/
module nulib.conv.algorithms.sdc;
import nulib.conv.algorithms.common;
import nulib.conv.integral;
import nulib.text.ascii;
import numem.core.math;

//
//          DECIMAL
//
struct Decimal {
@nogc nothrow:
public:
    enum long MAX_DIGITS = 800;
    enum long MAX_DIGITS_NO_OVERFLOW = 19;
    enum long RANGE = 2047;
    enum long MAX_SHIFT = (32UL << (~0UL >> 63))-4;

    ubyte[MAX_DIGITS] digits;
    uint numDigits;
    int decimalPoint;
    bool isNegative;
    bool isTruncated;

    // Trims the decimal bits.
    pragma(inline, true)
    void trim() pure {
        while(numDigits > 0 && digits[numDigits - 1] == 0)
            numDigits--;
    }

    // Returns the decimal rounded to nearest integer.
    pragma(inline, true)
    ulong round() pure {
        if (decimalPoint > MAX_DIGITS_NO_OVERFLOW)
            return ulong.max;

        ulong n = 0;
        size_t i = 0;

        // Add digits.
        for(i = 0; i < decimalPoint && i < numDigits; i++)
            n = (n * 10) + cast(ulong)(digits[i] - '0');
        
        // Keep going until decimal point.
        for(; i < decimalPoint; i++)
            n *= 10;

        // Handle rounding up.
        if (shouldRoundUp(this, decimalPoint))
            n++;

        return n;
    }

    // Left shift.
    pragma(inline, true)
    void opOpAssign(string op)(uint shift) pure 
    if (op == "<<") {
        if (shift == 0 || numDigits == 0)
            return;

        int delta = LUT_LEFT_SHIFTS[shift].delta;
        if (prefixLessThan(digits[0..numDigits], LUT_LEFT_SHIFTS[shift].cutoff))
            delta--;

        // rw indices
        int r = cast(int)numDigits;
        uint w = numDigits + delta;

        // Read one, write one.
        ulong n;
        for(r--; r >= 0; r--) {
            n += cast(ulong)(digits[r] - '0') << shift;
            ulong quo = n / 10;
            ulong rem = n - (10 * quo);
            w--;

            if (w < MAX_DIGITS) {
                digits[w] = cast(ubyte)(rem + '0');
            } else if (rem != 0) {
                isTruncated = true;
            }

            n = quo;
        }

        // Write extra digits.
        while (n > 0) {
            ulong quo = n / 10;
            ulong rem = n - (10 * quo);
            w--;

            if (w < MAX_DIGITS) {
                digits[w] = cast(ubyte)(rem + '0');
            } else if (rem != 0) {
                isTruncated = true;
            }

            n = quo;
        }

        numDigits += delta;
        if (numDigits > MAX_DIGITS) {
            numDigits = MAX_DIGITS;
        }
        decimalPoint += delta;
        this.trim();
        return;
    }

    // Right shift.
    pragma(inline, true)
    void opOpAssign(string op)(uint shift) pure 
    if (op == ">>") {
        if (shift == 0 || numDigits == 0)
            return;

        ulong mask = (1LU << shift) - 1;
        int r = 0;
        int w = 0;
        ulong n;

        // Read
        for(; n>>shift == 0; r++) {
            if (r >= numDigits) {
                if (n == 0) {
                    numDigits = 0;
                    return;
                }

                while((n >> shift) == 0) {
                    n = n * 10;
                    r++;
                }
                break;
            }

            uint c = cast(uint)digits[r];
            n = (n * 10) + (c - '0');
        }

        // Handle decimal point.
        decimalPoint -= r-1;
        if (decimalPoint < -RANGE) {
            numDigits = 0;
            decimalPoint = 0;
            isNegative = false;
            isTruncated = false;
            return;
        }

        // Write post-digits
        for(; r < numDigits; r++) {
            uint c = cast(uint)digits[r];
            ubyte nd = cast(ubyte)(n >> shift);

            n &= mask;
            digits[w++] = cast(ubyte)(nd + '0');
            n = (n * 10) + (c - '0');
        }

        // Write extra digits.
        while(n > 0) {
            ubyte nd = cast(ubyte)(n >> shift);
            n &= mask;

            if (w < MAX_DIGITS) {
                digits[w++] = cast(ubyte)(nd + '0');
            } else if (nd > 0) {
                isTruncated = true;
            }
        
            n = n * 10;
        }

        numDigits = w;
        trim();
    }

    /**
        Shifts by an integer amount, selecting left or right
        shift depending on the sign of the amount.

        Params:
            shift = The amount to shift by.
    */
    pragma(inline, true)
    void shift(int shift) pure {
        
        // Nothing to do.
        if (this.numDigits == 0)
            return;

        if (shift > 0) {

            // Perform shift in steps to avoid overflow.
            while(shift > MAX_SHIFT) {
                this <<= MAX_SHIFT;
                shift -= MAX_SHIFT;
            }
            this <<= cast(uint)shift;

        } else if (shift < 0) {

            // Perform shift in steps to avoid overflow.
            while(shift < -MAX_SHIFT) {
                this >>= MAX_SHIFT;
                shift += MAX_SHIFT;
            }
            this >>= cast(uint)-shift;
        }
    }

    FT toFloat(FT)(ref bool overflow) pure {
        Decimal d = this;
        int exp;
        ulong mant;

        enum int ft_mantbits = FloatInfo!(FT).MantissaBits; 
        enum int ft_expbits = FloatInfo!(FT).ExponentBits;
        enum int ft_bias = FloatInfo!(FT).Bias;

        // Case of no digits
        if (d.numDigits == 0) {

            ulong result = assemble!FT(0, ft_bias, d.isNegative);
            return *(cast(FT*)&result);
        }

        // Handle overflow
        if (d.decimalPoint > 310) {

            overflow = true;
            return d.isNegative ? -FT.infinity : FT.infinity;
        } else if (d.decimalPoint < -330) {

            ulong result = assemble!FT(0, ft_bias, d.isNegative);
            return *(cast(FT*)&result);
        }

        // Scale by powers of 2 until we're in the range 0.5..1.0
        while(d.decimalPoint > 0) {
            int n = 0;
            if (d.decimalPoint >= PNF64_POWTAB.length) {
                n = 27;
            } else {
                n = PNF64_POWTAB[d.decimalPoint];
            }

            d.shift(-n);
            exp += n;
        }
        while(d.decimalPoint < 0 || (d.decimalPoint == 0 && d.digits[0] < '5')) {
            int n = 0;
            if (-d.decimalPoint >= PNF64_POWTAB.length) {
                n = 27;
            } else {
                n = PNF64_POWTAB[-d.decimalPoint];
            }

            d.shift(n);
            exp -= n;
        }

        // Range is now 0.5..1.0, but float range is 1..2
        exp--;

        // Adjust if exponent is below minimal representable
        // form.
        if (exp < ft_bias+1) {
            int n = ft_bias + 1 - exp;
            d.shift(-n);
            exp += n;
        }

        // Handle overflow
        if (exp-ft_bias >= (1LU<<ft_expbits)-1) {
            
            overflow = true;
            return d.isNegative ? -FT.infinity : FT.infinity;
        }

        // Extract 1+ft_mantbits bits.
        d.shift(1 + ft_mantbits);
        mant = d.round();

        // Correct rounding error.
        if (mant == 2LU<<ft_mantbits) {
            mant >>= 1;
            exp++;

            // Handle overflow.
            if (exp-ft_bias >= (1LU<<ft_expbits)-1) {

                overflow = true;
                return d.isNegative ? -FT.infinity : FT.infinity;
            }
        }

        // Normalize.
        if ((mant & (1LU << ft_mantbits)) == 0) {
            exp = ft_bias;
        }

        ulong result = assemble!FT(mant, exp, d.isNegative);
        return *(cast(FT*)&result);
    }
}

/**
    Parses the given string as a decimal.

    Params:
        str = The string to parse.
        sep = The fractional point seperator.

    Returns:
        The parsed Decimal.
*/
Decimal parseDecimal(T)(T str, const(char) sep='.') @trusted @nogc nothrow pure {
    Decimal result;
    size_t i = 0;

    // No data.
    if (str.length == 0)
        return result;

    // Handle +/-
    result.isNegative = str[i] == '-';
    if (str[i] == '-' || str[i] == '+') {
        i++;
    }

    bool sawsep = false;
    bool sawdigits = false;
    loop: while(i < str.length) {
        char c = str[i++].toLower();
        switch(c) {

            // Skip underscores.
            case '_':
                continue loop;

            // Parse seperator.
            case sep:

                // Can't have decimal points of decimal points.
                if (sawsep)
                    return result;

                // Start parsing fractional.
                sawsep = true;
                result.decimalPoint = result.numDigits;
                continue loop;

            case '0': .. case '9':
                sawdigits = true;

                // Skip leading zeroes.
                if (c == '0' && result.numDigits == 0) {
                    result.decimalPoint--;
                    continue loop;
                }

                if (result.numDigits < result.MAX_DIGITS) {
                    result.digits[result.numDigits++] = c;
                } else if (c != '0') {
                    result.isTruncated = true;
                }

                continue loop;

            default: break loop;
        }
    }

    // Backtrack one, so that we can parse exponents.
    i--;

    // No digits.
    if (!sawdigits) {
        return result;
    }
    
    // No fractional
    if (!sawsep) {
        result.decimalPoint = result.numDigits;
    }

    // Parse exponent
    if (i < str.length && str[i].toLower() == 'e') {
        i++;

        // No exponent?
        if (i >= str.length)
            return result;

        // Parse sign
        int expSign = (str[i] == '-') ? -1 : 1;
        if (str[i] == '-' || str[i] == '+')
            i++;

        // Not a digit?
        if (i >= str.length || !str[i].isDigit)
            return result;

        int exp = 0;
        for(; i < str.length && (str[i].isDigit || str[i] == '_'); i++) {
            if (str[i] == '_') {

                // Skip underscores.
                continue;
            } else if (exp < 10_000) {
                if (str[i] == '0' && exp == 0) {
                    continue;
                }

                exp = (exp*10) + cast(int)(str[i] - '0');
                continue;
            }
        }
        result.decimalPoint += exp * expSign;
    }
    return result;
}



//
//          IMPLEMENTATION DETAILS
//
private:

// Get whether decimal should be rounded up if we remove nd digits from it.
bool shouldRoundUp(ref Decimal d, int nd) @nogc nothrow pure {
    if (nd < 0 || nd >= d.numDigits)
        return false;

    // We're exactly halfway, round to even.
    if (d.digits[nd] == '5' && nd+1 == d.numDigits) {
        
        // Truncated should always round up.
        if (d.isTruncated)
            return true;

        return nd > 0 && (d.digits[nd-1]-'0')%2 != 0;
    }

    return d.digits[nd] >= '5';
}

/// Assembles bits together to a proper float representation.
pragma(inline, true)
ulong assemble(FT)(ulong mantissa, int exp, bool negative) @nogc nothrow pure {
    enum int ft_bias = FloatInfo!(FT).Bias;
    enum int ft_expbits = FloatInfo!(FT).ExponentBits;
    enum int ft_mantbits = FloatInfo!(FT).MantissaBits;

    enum ft_mantmask = (1LU << ft_mantbits)-1;
    enum ft_expmask = (1LU << ft_expbits)-1;

    ulong result = cast(ulong)mantissa & ft_mantmask;
    result |= cast(ulong)((exp-ft_bias) & ft_expmask) << ft_mantbits;

    if (negative)
        result |= 1LU << ft_mantbits << ft_expbits;
    return result;
}

__gshared const immutable(int)[] PNF64_POWTAB = [
    1,  3,  6,  9,  13, 16, 19, 23, 26, 29,
    33, 36, 39, 43, 46, 49, 53, 56, 59,
];




//
//          Left-shift optimisation, credit goes to Ken Thompson.
//
struct lshift_entry { int delta; string cutoff; }
__gshared const immutable(lshift_entry)[] LUT_LEFT_SHIFTS = __ctfe_generate_lshifts(60);

// Prefix helper.
pragma(inline, true)
bool prefixLessThan(ubyte[] buf, string str) @nogc nothrow pure {
    foreach(i; 0..str.length) {
        if (i >= buf.length)
            return true;

        if (buf[i] != str[i])
            return buf[i] < str[i];
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