<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# @deckyard/money

Currency amounts that are always exact: prices, invoices, payouts, ledgers.
A float cannot hold 0.10 and drifts with every sum; this deck keeps an
amount as an `int` of the currency's minor units, cents for EUR, fils for
KWD, yen for JPY, and does everything that can land between two minor units
through the `decimal` library, rounding in the mode the caller names.

## Conventions

Snippets assume this import:

```jennifer
import "@deckyard/money/" as money;

def price as money.Money init money.parse("19.99", "EUR");
io.printf("%s\n", money.format(money.multiply($price, "3", "half-even")));   # 59.97
```

A `Money` is two plain fields, `amount` and `currency`: 19.99 EUR is
`Money{amount: 1999, currency: "EUR"}`. Store those two wherever the program
keeps its data; `==` compares them. Factors, rates and ratios are decimal
strings such as `"1.19"`; a `decimal.Decimal` becomes one with
`decimal.toString`.

## Errors

Every failure of the deck is `Error{kind: "money"}`:

- an unknown currency: `money: unknown currency: ABC`;
- amounts of two currencies in one operation:
  `money: different currencies: EUR and USD`;
- text that is not an amount, or has too many places:
  `money: "12.345" has more than 2 decimal places for EUR`;
- a mode that is not one of `MODES`;
- a result past the `int` range: `money: amount out of range`.

A string the caller passed appears in a message cut to 20 characters, with
anything but printable ASCII shown as `?`, so a message stays one short line.

## Requirements

Jennifer 0.26.0 or newer, `jennifer` or `jennifer-tiny`. No capabilities.
