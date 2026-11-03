<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Amounts

## Making one

From minor units, from text, or from a decimal:

```jennifer
def a as money.Money init money.fromMinor(1234, "EUR");    # 12.34 EUR
def b as money.Money init money.parse("12.34", "EUR");     # the same
def c as money.Money init money.zero("JPY");
def d as money.Money init money.fromDecimal(decimal.from("12.345"), "EUR", "half-even");   # 12.34 EUR
```

A currency is its ISO 4217 code in capitals. An unknown code is an error,
never a guess; see [Currencies](currencies.md).

## Text

`parse` reads digits with an optional `-` and a fraction after a dot. It
refuses everything else: an exponent, spaces, `+`, a decimal comma, digit
separators. Places beyond the currency's are refused unless they are zeros:

```jennifer
money.parse("12.3", "EUR");     # 12.30 EUR
money.parse("12.340", "EUR");   # 12.34 EUR
money.parse("12.345", "EUR");   # error: more than 2 decimal places for EUR
money.parse("1200", "JPY");     # 1200 JPY
```

To accept more places and round them, go through `decimal`:

```jennifer
money.fromDecimal(decimal.from($text), "EUR", "half-up");
```

`format` writes what `parse` reads, always with the currency's places:

```jennifer
money.format(money.fromMinor(500, "EUR"));    # "5.00"
money.format(money.fromMinor(-5, "EUR"));     # "-0.05"
money.format(money.fromMinor(1200, "JPY"));   # "1200"
money.format(money.fromMinor(1, "KWD"));      # "0.001"
```

There is no grouping, currency symbol or decimal comma: how an amount is
shown is a matter of locale, which this deck leaves to the program.

## Storing

Keep `amount` as an integer column or JSON number and `currency` beside it,
and rebuild the value with `fromMinor`. An `int` holds about 9.2 x 10^16
minor units, 92 quadrillion euros. A result past that is a `money` error,
not a wrapped number.

An amount whose currency the deck does not know, such as the zero value of
`Money` or one built by hand, is refused by every function that computes
with it.

## Comparing

`==` is equality; amounts of different currencies are simply not equal.
Ordering refuses to compare across currencies:

```jennifer
if (money.lessThan($balance, $price)) {
    # not enough
}
money.compare($a, $b);   # -1, 0 or 1
money.isZero($m);
money.isNegative($m);
money.isPositive($m);
```

## Decimals

`toDecimal` gives the amount in major units as a `decimal.Decimal` at the
currency's scale, for computations the deck does not offer:

```jennifer
def value as decimal.Decimal init money.toDecimal(money.fromMinor(1200, "EUR"));   # 12.00
```

Bring the result back with `fromDecimal` and a rounding mode.
