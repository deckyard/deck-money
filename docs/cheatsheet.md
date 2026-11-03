<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# money cheatsheet

Every export of `@deckyard/money`. Guides are listed in
[the introduction](index.md).

```jennifer
import "@deckyard/money/" as money;
```

Every failure is `Error{kind: "money"}`. A `code` is an ISO 4217 code such
as `"EUR"`; a `mode` is one of `MODES`. Factors, rates and ratios are
decimal strings such as `"1.19"`.

## Constants

| Constant | Value | Meaning |
|---|---|---|
| `ERROR_KIND` | `"money"` | the `kind` of every error the deck throws |
| `MODES` | `["half-even", "half-up", "half-down", "up", "down", "ceiling", "floor"]` | the rounding modes |
| `MAX_TEXT` | `50` | the longest amount, factor, rate or ratio string |
| `MAX_PARTS` | `100000` | the most parts `allocate` and `allocateTo` make |

## Types

### `Money`

| Field | Meaning |
|---|---|
| `amount as int` | minor units: 1234 for 12.34 EUR |
| `currency as string` | the ISO 4217 code |

## Making and reading

| Function | Returns | Does |
|---|---|---|
| `money.fromMinor(amount, code)` | `Money` | an amount of minor units |
| `money.zero(code)` | `Money` | zero |
| `money.parse(text, code)` | `Money` | read `"12.34"`; extra places only if zeros |
| `money.format(m)` | `string` | `"12.34"`, `"1200"` for JPY |
| `money.fromDecimal(d, code, mode)` | `Money` | a decimal in major units, rounded |
| `money.toDecimal(m)` | `decimal.Decimal` | the amount in major units |

## Currencies

| Function | Returns | Does |
|---|---|---|
| `money.isCurrency(code)` | `bool` | whether the code is in the table |
| `money.digits(code)` | `int` | the minor units: 0, 2, 3 or 4 |
| `money.currencies()` | `list of string` | every code, sorted |
| `money.published()` | `string` | the date of the ISO 4217 list used |

## Arithmetic

| Function | Returns | Does |
|---|---|---|
| `money.add(a, b)` | `Money` | `a + b` |
| `money.subtract(a, b)` | `Money` | `a - b` |
| `money.sum(ms, code)` | `Money` | the total of a list; zero when empty |
| `money.negate(m)` | `Money` | `-m` |
| `money.absolute(m)` | `Money` | `\|m\|` |
| `money.multiply(m, factor, mode)` | `Money` | `m * factor`, rounded |
| `money.divide(m, divisor, mode)` | `Money` | `m / divisor`, rounded |
| `money.allocate(m, ratios)` | `list of Money` | split by ratios; the parts sum to `m` |
| `money.allocateTo(m, n)` | `list of Money` | split into `n` equal parts |
| `money.exchange(m, code, rate, mode)` | `Money` | into another currency at `rate`, rounded |

## Comparing

| Function | Returns | Does |
|---|---|---|
| `money.compare(a, b)` | `int` | -1, 0 or 1 |
| `money.lessThan(a, b)` | `bool` | `a < b` |
| `money.greaterThan(a, b)` | `bool` | `a > b` |
| `money.isZero(m)` | `bool` | `m == 0` |
| `money.isNegative(m)` | `bool` | `m < 0` |
| `money.isPositive(m)` | `bool` | `m > 0` |

## The currencies module

`import "@deckyard/money/currencies.j" as currencies;` reads the table
itself. It is generated; see [Currencies](currencies.md).

| Constant | Value | Meaning |
|---|---|---|
| `currencies.PUBLISHED` | `"2026-09-17"` | the date of the ISO 4217 list |
| `currencies.DIGITS` | `{"AED": 2, ...}` | each code's minor units |
