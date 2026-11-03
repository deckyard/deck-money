<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Arithmetic

## Adding

`add`, `subtract`, `sum`, `negate` and `absolute` are exact. Amounts must be
in the same currency:

```jennifer
def total as money.Money init money.sum($lines, "EUR");   # zero for no lines
def due as money.Money init money.subtract($total, $paid);
```

`sum` takes the currency so that an empty list still has one.

## Rounding modes

Multiplying, dividing and exchanging can land between two minor units, so
each takes a mode. There is no default: whether a tax rounds half up, half
to even or always up is the program's rule, not the deck's.

| Mode | Rounds | 2.5 | -2.5 | 1.6 | -1.1 |
|---|---|---|---|---|---|
| `half-even` | to the nearest, a tie to the even neighbour | 2 | -2 | 2 | -1 |
| `half-up` | to the nearest, a tie away from zero | 3 | -3 | 2 | -1 |
| `half-down` | to the nearest, a tie toward zero | 2 | -2 | 2 | -1 |
| `up` | away from zero | 3 | -3 | 2 | -2 |
| `down` | toward zero | 2 | -2 | 1 | -1 |
| `ceiling` | toward positive infinity | 3 | -2 | 2 | -1 |
| `floor` | toward negative infinity | 2 | -3 | 1 | -2 |

`money.MODES` lists them.

## Multiplying and dividing

The factor is a decimal string, computed exactly; only the result is
rounded:

```jennifer
money.multiply(money.fromMinor(1999, "EUR"), "1.19", "half-up");   # 23.79 EUR
money.multiply(money.fromMinor(1000, "EUR"), "0.075", "down");     # 0.75 EUR
money.divide(money.fromMinor(1000, "EUR"), "3", "half-even");      # 3.33 EUR
```

Dividing and multiplying back does not give the amount again:
`3 x 3.33` is 9.99. To share an amount out, allocate it.

## Allocating

`allocate` splits an amount by ratios, `allocateTo` into equal parts. The
parts always add up to the amount:

```jennifer
money.allocateTo(money.fromMinor(1000, "EUR"), 3);              # 3.34, 3.33, 3.33
money.allocate(money.fromMinor(1000, "EUR"), ["50", "30", "20"]);   # 5.00, 3.00, 2.00
money.allocate(money.fromMinor(5, "EUR"), ["0.7", "0.3"]);        # 0.04, 0.01
```

Each part first gets its exact share rounded toward zero. The minor units
left over then go one each to the parts whose share was cut the most, the
earlier part on a tie; `allocateTo` therefore gives them to the first parts.
A ratio of zero gets nothing. A negative amount splits like its positive
mirror.

Ratios are decimal strings, not negative and not all zero. There can be at
most `MAX_PARTS` (100000) parts.

## Exchanging

`exchange` takes a rate the caller supplies: units of the target currency
per unit of the amount's. The deck fetches no rates; take them from a
source the program trusts and pass them in as text:

```jennifer
money.exchange(money.fromMinor(10000, "EUR"), "USD", "1.0832", "half-even");   # 108.32 USD
money.exchange(money.fromMinor(10000, "EUR"), "JPY", "162.345", "half-even");  # 16234 JPY
```

The minor units of both currencies are taken into account, so EUR to JPY
and JPY to KWD need no adjusting. The rate must be above zero.

## Limits

Amounts, factors, rates and ratios are at most `MAX_TEXT` (50) characters,
so a hostile string cannot become a number with a million digits.
