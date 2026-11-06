# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * Exact currency amounts.
 *
 * A `Money` holds an amount in whole minor units, the cents of a euro or the
 * fils of a dinar, and an ISO 4217 currency code: 12.34 EUR is
 * `Money{amount: 1234, currency: "EUR"}`. Amounts are exact, compare with
 * `==` and store as a plain `int`. Anything that can land between two minor
 * units (multiplying, dividing, exchanging) takes a rounding mode, and
 * `allocate` splits an amount so that no minor unit is lost or created.
 *
 * Factors, rates and ratios are decimal strings such as `"1.19"`, computed
 * exactly with the `decimal` library; no float touches an amount. Amounts of
 * different currencies never mix. Every failure of the deck is
 * `Error{kind: "money"}`.
 *
 * @module money
 * @example
 *   def net as money.Money init money.parse("19.99", "EUR");
 *   def gross as money.Money init money.multiply($net, "1.19", "half-up");
 *   io.printf("%s\n", money.format($gross));   # 23.79
 */
use convert;
use decimal;
use lists;
use maps;
use regex;
use strings;

import "./currencies.j" as iso;

/** The `kind` of every error the deck throws. */
export def const ERROR_KIND as string init "money";

/**
 * The rounding modes, as the `decimal` library names them. Every function
 * that can land between two minor units takes one; there is no default.
 */
export def const MODES as list of string init [
    "half-even",
    "half-up",
    "half-down",
    "up",
    "down",
    "ceiling",
    "floor"
];

/**
 * The longest amount, factor, rate or ratio string accepted. An `int` holds
 * at most 19 digits, so this leaves room for a long rate and trailing zeros
 * while keeping a hostile string from turning into a huge number.
 */
export def const MAX_TEXT as int init 50;

/** The most parts `allocate` and `allocateTo` make. */
export def const MAX_PARTS as int init 100000;

/**
 * An amount of money.
 *
 * @field amount {int} minor units: 1234 for 12.34 EUR
 * @field currency {string} the ISO 4217 code
 */
export def struct Money {
    amount as int,
    currency as string
};

# What `parse` and the factor strings accept: no sign but `-`, no exponent,
# no spaces or digit separators.
def const NUMBER_PATTERN as string init "^-?[0-9]+([.][0-9]+)?$";

def const CODE_PATTERN as string init "^[A-Z][A-Z][A-Z]$";

# How much of a caller's string an error message repeats.
def const SHOWN as int init 20;

func fail(msg as string) {
    throw Error{kind: ERROR_KIND, message: "money: " + $msg};
}

# A caller's string as an error message repeats it: cut to SHOWN
# characters, with anything but printable ASCII as `?`, so that a message
# stays short and cannot carry a line break or a terminal escape into a log.
func shown(text as string) {
    def cut as string init $text;
    def more as string init "";
    if (len($text) > SHOWN) {
        $cut = strings.substring($text, 0, SHOWN);
        $more = "...";
    }
    return "\"" + regex.replace("[^ -~]", $cut, "?") + $more + "\"";
}

# The currency's minor units, or an error for an unknown code.
func placesOf(code as string) {
    if (not regex.matches(CODE_PATTERN, $code)) {
        fail("not a currency code: " + shown($code));
    }
    if (not maps.has(iso.DIGITS, $code)) {
        fail("unknown currency: " + $code);
    }
    return iso.DIGITS[$code];
}

func checkMode(mode as string) {
    if (not lists.contains(MODES, $mode)) {
        fail("unknown rounding mode " + shown($mode) + "; use one of " + strings.join(MODES, ", "));
    }
}

func checkSame(a as Money, b as Money) {
    placesOf($a.currency);
    if ($a.currency != $b.currency) {
        fail("different currencies: " + $a.currency + " and " + $b.currency);
    }
}

# A decimal string the deck accepts for a factor, rate or ratio.
func number(text as string, what as string) {
    if (len($text) > MAX_TEXT) {
        fail($what + " longer than " + convert.toString(MAX_TEXT) + " characters");
    }
    if (not regex.matches(NUMBER_PATTERN, $text)) {
        fail($what + " is not a decimal number: " + shown($text));
    }
    return decimal.from($text);
}

# A whole number of minor units back to an int.
func units(d as decimal.Decimal) {
    try {
        return decimal.toInt($d);
    } catch (e) {
        fail("amount out of range");
    }
    return 0;
}

# One minor unit of a currency with `places` digits, at that scale: 0.01.
func unit(places as int) {
    return decimal.div(1, decimal.pow(10, $places), $places);
}

func plus(x as int, y as int) {
    def total as decimal.Decimal init decimal.add($x, $y);
    return units($total);
}

/**
 * An amount of minor units.
 *
 * @param amount {int} minor units: 1234 for 12.34 EUR
 * @param code {string} an ISO 4217 code
 * @return {Money} the amount
 * @throws {Error} on an unknown currency
 * @example
 *   money.fromMinor(1234, "EUR");   # 12.34 EUR
 */
export func fromMinor(amount as int, code as string) {
    placesOf($code);
    return Money{amount: $amount, currency: $code};
}

/**
 * Nothing, in a currency.
 *
 * @param code {string} an ISO 4217 code
 * @return {Money} zero
 * @throws {Error} on an unknown currency
 */
export func zero(code as string) {
    return fromMinor(0, $code);
}

/**
 * Whether a code is in the ISO 4217 table.
 *
 * @param code {string} a code such as `"EUR"`
 * @return {bool} whether the deck knows it
 */
export func isCurrency(code as string) {
    return maps.has(iso.DIGITS, $code);
}

/**
 * A currency's minor units: the digits after the point.
 *
 * @param code {string} an ISO 4217 code
 * @return {int} 0 for JPY, 2 for EUR, 3 for KWD
 * @throws {Error} on an unknown currency
 */
export func digits(code as string) {
    return placesOf($code);
}

/**
 * Every code in the ISO 4217 table, sorted.
 *
 * @return {list of string} the codes
 */
export func currencies() {
    return lists.sort(maps.keys(iso.DIGITS));
}

/**
 * The publication date of the ISO 4217 list the table comes from.
 *
 * @return {string} a date such as `"2026-09-17"`
 */
export func published() {
    return iso.PUBLISHED;
}

/**
 * Read an amount written with a dot: `"12.34"`, `"-0.5"`, `"1200"`. Places
 * beyond the currency's are refused unless they are zeros, so `"12.340"`
 * is 12.34 EUR and `"12.345"` an error.
 *
 * @param text {string} digits, optionally a `-` and a fraction
 * @param code {string} an ISO 4217 code
 * @return {Money} the amount
 * @throws {Error} on malformed text, too many places or an unknown currency
 * @example
 *   money.parse("12.34", "EUR");   # Money{amount: 1234, currency: "EUR"}
 *   money.parse("1200", "JPY");    # Money{amount: 1200, currency: "JPY"}
 */
export func parse(text as string, code as string) {
    def places as int init placesOf($code);
    def value as decimal.Decimal init number($text, "amount");
    def scaled as decimal.Decimal init decimal.mul($value, decimal.pow(10, $places));
    if (not decimal.isInteger($scaled)) {
        fail(
            "\"" + $text + "\" has more than " + convert.toString($places) +
                " decimal places for " + $code);
    }
    return Money{amount: units($scaled), currency: $code};
}

/**
 * Write an amount with a dot and the currency's places: `"12.34"`,
 * `"-0.05"`, `"1200"` for JPY. No grouping, symbol or code.
 *
 * @param m {Money} the amount
 * @return {string} the text `parse` reads back
 * @example
 *   money.format(money.fromMinor(500, "EUR"));   # "5.00"
 */
export func format(m as Money) {
    return decimal.toString(toDecimal($m));
}

/**
 * The amount in major units, at the currency's scale: 12.34 for 1234 EUR.
 *
 * @param m {Money} the amount
 * @return {decimal.Decimal} the value
 * @throws {Error} on an unknown currency
 */
export func toDecimal(m as Money) {
    return decimal.mul($m.amount, unit(placesOf($m.currency)));
}

/**
 * An amount from a decimal in major units, rounded to the currency's places.
 *
 * @param d {decimal.Decimal} the value, such as 12.345
 * @param code {string} an ISO 4217 code
 * @param mode {string} one of `MODES`
 * @return {Money} the amount
 * @throws {Error} on an unknown currency or mode, or past the `int` range
 * @example
 *   money.fromDecimal(decimal.from("12.345"), "EUR", "half-even");   # 12.34 EUR
 */
export func fromDecimal(d as decimal.Decimal, code as string, mode as string) {
    def places as int init placesOf($code);
    checkMode($mode);
    def scaled as decimal.Decimal init decimal.mul($d, decimal.pow(10, $places));
    return Money{amount: units(decimal.round($scaled, 0, $mode)), currency: $code};
}

/**
 * The sum of two amounts.
 *
 * @param a {Money} the first amount
 * @param b {Money} the second, in the same currency
 * @return {Money} `a + b`
 * @throws {Error} on different currencies or past the `int` range
 */
export func add(a as Money, b as Money) {
    checkSame($a, $b);
    return Money{amount: plus($a.amount, $b.amount), currency: $a.currency};
}

/**
 * The difference of two amounts.
 *
 * @param a {Money} the amount
 * @param b {Money} what to take away, in the same currency
 * @return {Money} `a - b`
 * @throws {Error} on different currencies or past the `int` range
 */
export func subtract(a as Money, b as Money) {
    checkSame($a, $b);
    return Money{amount: units(decimal.sub($a.amount, $b.amount)), currency: $a.currency};
}

/**
 * The sum of a list of amounts, zero for an empty list.
 *
 * @param ms {list of Money} the amounts
 * @param code {string} the currency every amount must be in
 * @return {Money} the total
 * @throws {Error} on another currency in the list or past the `int` range
 */
export func sum(ms as list of Money, code as string) {
    placesOf($code);
    def total as decimal.Decimal init decimal.from(0);
    for (def m in $ms) {
        if ($m.currency != $code) {
            fail("different currencies: " + $code + " and " + $m.currency);
        }
        $total = decimal.add($total, $m.amount);
    }
    return Money{amount: units($total), currency: $code};
}

/**
 * The amount with the opposite sign.
 *
 * @param m {Money} the amount
 * @return {Money} `-m`
 * @throws {Error} past the `int` range
 */
export func negate(m as Money) {
    placesOf($m.currency);
    return Money{amount: units(decimal.neg($m.amount)), currency: $m.currency};
}

/**
 * The amount without its sign.
 *
 * @param m {Money} the amount
 * @return {Money} `|m|`
 * @throws {Error} past the `int` range
 */
export func absolute(m as Money) {
    placesOf($m.currency);
    return Money{amount: units(decimal.abs($m.amount)), currency: $m.currency};
}

/**
 * Multiply an amount and round to whole minor units.
 *
 * @param m {Money} the amount
 * @param factor {string} a decimal such as `"1.19"` or `"-0.5"`
 * @param mode {string} one of `MODES`
 * @return {Money} the product
 * @throws {Error} on a malformed factor, an unknown mode or past the `int` range
 * @example
 *   money.multiply(money.fromMinor(1999, "EUR"), "1.19", "half-up");   # 23.79 EUR
 */
export func multiply(m as Money, factor as string, mode as string) {
    placesOf($m.currency);
    checkMode($mode);
    def product as decimal.Decimal init decimal.mul($m.amount, number($factor, "factor"));
    return Money{amount: units(decimal.round($product, 0, $mode)), currency: $m.currency};
}

/**
 * Divide an amount and round to whole minor units.
 *
 * @param m {Money} the amount
 * @param divisor {string} a decimal such as `"3"` or `"1.19"`, not zero
 * @param mode {string} one of `MODES`
 * @return {Money} the quotient
 * @throws {Error} on a malformed or zero divisor, or an unknown mode
 * @example
 *   money.divide(money.fromMinor(1000, "EUR"), "3", "half-even");   # 3.33 EUR
 */
export func divide(m as Money, divisor as string, mode as string) {
    placesOf($m.currency);
    checkMode($mode);
    def by as decimal.Decimal init number($divisor, "divisor");
    if (decimal.sign($by) == 0) {
        fail("division by zero");
    }
    return Money{amount: units(decimal.div($m.amount, $by, 0, $mode)), currency: $m.currency};
}

# Pad a non-negative whole decimal with zeros to `width` digits, so that
# strings sort as the numbers do.
func padded(d as decimal.Decimal, width as int) {
    def text as string init decimal.toString($d);
    return strings.repeat("0", $width - len($text)) + $text;
}

# Split `amount` by whole-number weights: each part gets its share rounded
# toward zero, and the minor units left over go one each to the parts with
# the largest remainders, the earlier part on a tie. A part of weight 0 has
# no remainder and so gets nothing.
func split(amount as int, code as string, weights as list of decimal.Decimal) {
    def whole as decimal.Decimal init decimal.abs($amount);
    def total as decimal.Decimal init decimal.sum($weights);
    def shares as list of decimal.Decimal init [];
    def keys as list of string init [];
    def given as decimal.Decimal init decimal.from(0);
    def width as int init len(decimal.toString($total));
    def indexWidth as int init len(convert.toString(len($weights)));
    for (def i as int init 0; $i < len($weights); $i = $i + 1) {
        def exact as decimal.Decimal init decimal.mul($whole, $weights[$i]);
        def share as decimal.Decimal init decimal.div($exact, $total, 0, "down");
        def rest as decimal.Decimal init decimal.sub($exact, decimal.mul($share, $total));
        $shares[] = $share;
        $given = decimal.add($given, $share);
        # Ascending order of this key is descending remainder, then index.
        $keys[] = padded(decimal.sub(decimal.sub($total, 1), $rest), $width) + " " +
            padded(decimal.from($i), $indexWidth);
    }
    $keys = lists.sort($keys);
    def left as int init decimal.toInt(decimal.sub($whole, $given));
    for (def k as int init 0; $k < $left; $k = $k + 1) {
        def at as int init convert.toInt(strings.split($keys[$k], " ")[1]);
        $shares[$at] = decimal.add($shares[$at], 1);
    }
    def parts as list of Money init [];
    for (def share in $shares) {
        if ($amount < 0) {
            $share = decimal.neg($share);
        }
        $parts[] = Money{amount: units($share), currency: $code};
    }
    return $parts;
}

func checkParts(n as int) {
    if ($n < 1) {
        fail("nothing to allocate to");
    }
    if ($n > MAX_PARTS) {
        fail("more than " + convert.toString(MAX_PARTS) + " parts");
    }
}

/**
 * Split an amount by ratios. The parts always add up to the amount: the
 * minor units that do not divide go one each to the parts whose share was
 * cut the most, the earlier part on a tie. A negative amount splits like
 * its positive mirror.
 *
 * @param m {Money} the amount
 * @param ratios {list of string} decimals, not negative, not all zero:
 *   `["1", "1", "1"]`, `["70", "30"]` or `["0.7", "0.3"]`
 * @return {list of Money} one part per ratio
 * @throws {Error} on a malformed, negative or all-zero ratio list
 * @example
 *   money.allocate(money.fromMinor(1000, "EUR"), ["1", "1", "1"]);   # 3.34, 3.33, 3.33
 *   money.allocate(money.fromMinor(5, "EUR"), ["70", "30"]);         # 0.04, 0.01
 */
export func allocate(m as Money, ratios as list of string) {
    placesOf($m.currency);
    checkParts(len($ratios));
    def values as list of decimal.Decimal init [];
    def places as int init 0;
    for (def r in $ratios) {
        def value as decimal.Decimal init number($r, "ratio");
        if (decimal.sign($value) < 0) {
            fail("negative ratio: " + $r);
        }
        if (decimal.scale($value) > $places) {
            $places = decimal.scale($value);
        }
        $values[] = $value;
    }
    # Whole-number weights in the same proportions: 0.7 and 0.3 become 7 and 3.
    def weights as list of decimal.Decimal init [];
    def anything as bool init false;
    for (def value in $values) {
        def weight as decimal.Decimal init decimal.mul($value, decimal.pow(10, $places));
        $weights[] = decimal.round($weight, 0);
        if (decimal.sign($value) > 0) {
            $anything = true;
        }
    }
    if (not $anything) {
        fail("every ratio is zero");
    }
    return split($m.amount, $m.currency, $weights);
}

/**
 * Split an amount into equal parts. The minor units that do not divide go
 * one each to the first parts.
 *
 * @param m {Money} the amount
 * @param n {int} how many parts, 1 to `MAX_PARTS`
 * @return {list of Money} `n` parts
 * @throws {Error} on `n` out of range
 * @example
 *   money.allocateTo(money.fromMinor(1000, "EUR"), 3);   # 3.34, 3.33, 3.33
 */
export func allocateTo(m as Money, n as int) {
    placesOf($m.currency);
    checkParts($n);
    def weights as list of decimal.Decimal init [];
    for (def i as int init 0; $i < $n; $i = $i + 1) {
        $weights[] = decimal.from(1);
    }
    return split($m.amount, $m.currency, $weights);
}

/**
 * Exchange an amount into another currency at a rate the caller supplies,
 * rounded to the target's minor units.
 *
 * @param m {Money} the amount
 * @param code {string} the ISO 4217 code to exchange into
 * @param rate {string} units of `code` per unit of `m`'s currency, above zero:
 *   `"1.0832"` from EUR to USD
 * @param mode {string} one of `MODES`
 * @return {Money} the amount in `code`
 * @throws {Error} on an unknown currency or mode, a malformed rate or past
 *   the `int` range
 * @example
 *   money.exchange(money.fromMinor(10000, "EUR"), "JPY", "162.345", "half-even");   # 16234 JPY
 */
export func exchange(m as Money, code as string, rate as string, mode as string) {
    def from as int init placesOf($m.currency);
    def into as int init placesOf($code);
    checkMode($mode);
    def by as decimal.Decimal init number($rate, "rate");
    if (decimal.sign($by) <= 0) {
        fail("rate must be above zero: " + $rate);
    }
    def value as decimal.Decimal init decimal.mul($m.amount, $by);
    if ($into >= $from) {
        $value = decimal.mul($value, decimal.pow(10, $into - $from));
    } else {
        $value = decimal.div($value, decimal.pow(10, $from - $into));
    }
    return Money{amount: units(decimal.round($value, 0, $mode)), currency: $code};
}

/**
 * Compare two amounts.
 *
 * @param a {Money} the first amount
 * @param b {Money} the second, in the same currency
 * @return {int} -1, 0 or 1 as `a` is less than, equal to or greater than `b`
 * @throws {Error} on different currencies
 */
export func compare(a as Money, b as Money) {
    checkSame($a, $b);
    if ($a.amount < $b.amount) {
        return -1;
    }
    if ($a.amount > $b.amount) {
        return 1;
    }
    return 0;
}

/**
 * Whether `a` is less than `b`.
 *
 * @param a {Money} the first amount
 * @param b {Money} the second, in the same currency
 * @return {bool} `a < b`
 * @throws {Error} on different currencies
 */
export func lessThan(a as Money, b as Money) {
    return compare($a, $b) < 0;
}

/**
 * Whether `a` is greater than `b`.
 *
 * @param a {Money} the first amount
 * @param b {Money} the second, in the same currency
 * @return {bool} `a > b`
 * @throws {Error} on different currencies
 */
export func greaterThan(a as Money, b as Money) {
    return compare($a, $b) > 0;
}

/**
 * Whether an amount is zero.
 *
 * @param m {Money} the amount
 * @return {bool} `m == 0`
 * @throws {Error} on an unknown currency
 */
export func isZero(m as Money) {
    placesOf($m.currency);
    return $m.amount == 0;
}

/**
 * Whether an amount is below zero.
 *
 * @param m {Money} the amount
 * @return {bool} `m < 0`
 * @throws {Error} on an unknown currency
 */
export func isNegative(m as Money) {
    placesOf($m.currency);
    return $m.amount < 0;
}

/**
 * Whether an amount is above zero.
 *
 * @param m {Money} the amount
 * @return {bool} `m > 0`
 * @throws {Error} on an unknown currency
 */
export func isPositive(m as Money) {
    placesOf($m.currency);
    return $m.amount > 0;
}
