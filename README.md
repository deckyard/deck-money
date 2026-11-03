# @deckyard/money

[![test](https://github.com/deckyard/deck-money/actions/workflows/test.yml/badge.svg)](https://github.com/deckyard/deck-money/actions/workflows/test.yml)
[![Documentation](https://img.shields.io/badge/docs-github%20pages-blue)](https://deckyard.github.io/deck-money/)
[![release](https://img.shields.io/github/v/release/deckyard/deck-money)](https://github.com/deckyard/deck-money/releases/latest)

Exact currency amounts for [Jennifer](https://jennifer-lang.dev/), on the
`decimal` library. An amount is an `int` of minor units with its ISO 4217
code, so it is exact, compares with `==` and stores as a plain number.
Multiplying, dividing and exchanging round to whole minor units in the mode
the caller names; `allocate` splits an amount without losing or creating a
cent; amounts of different currencies never mix.

**[Documentation](https://deckyard.github.io/deck-money/)**

## Install

```sh
jvc add @deckyard/money
```

This vendors the deck to `vendor/<scope>/money/`. Without `jvc`, unpack the
`src/` subtree of a release archive (`<scope>-money-<version>.tar.gz`) there.

## Usage

```jennifer
import "@deckyard/money/" as money;

def net as money.Money init money.parse("19.99", "EUR");
def gross as money.Money init money.multiply($net, "1.19", "half-up");
io.printf("%s EUR\n", money.format($gross));   # 23.79 EUR

for (def part in money.allocate($gross, ["1", "1", "1"])) {
    io.printf("%s ", money.format($part));      # 7.93 7.93 7.93
}
```

## Requirements

Jennifer 0.26.0 or newer, `jennifer` or `jennifer-tiny`. No capabilities:
the deck is pure computation.

## Development

```sh
tools/check-all.sh                   # the full gate, as CI runs it
jennifer test src/money_test.j       # the test overlay
tools/gen-currencies.sh              # refresh the ISO 4217 table
tools/check-docs.sh                  # docs against the code
tools/pack.sh dist                   # build the release archive
```

## Licence

LGPL-3.0-only, see [LICENSE](LICENSE). Copyright (C) 2026 mplx &lt;mplx@jennifer-lang.dev&gt;.

`tools/check-headers.sh` checks every source file's SPDX header against
`deck.toml`.
