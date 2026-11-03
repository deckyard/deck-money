<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Currencies

The deck knows the currencies of the ISO 4217 list and their minor units,
the digits after the point:

```jennifer
money.isCurrency("EUR");   # true
money.digits("JPY");       # 0
money.digits("KWD");       # 3
money.currencies();        # ["AED", "AFN", ...], sorted
money.published();         # the date of the list the table was made from
```

Codes the list gives no minor units are left out: gold and the other
precious metals, `XTS` (testing) and `XXX` (no currency). Fund codes such as
`CLF` (4 places) are in. There are no custom currencies.

## The table

`src/currencies.j` holds the table, generated from the list SIX publishes for
ISO. The list is amended a few times a year, usually for a new currency or a
redenomination. To bring the table up to date:

```sh
tools/gen-currencies.sh          # downloads the list
git diff src/currencies.j        # review what changed
```

and release. `tools/gen-currencies.sh list-one.xml` uses a file already
downloaded. The generator stops on a list in an unexpected shape, so a
change of format at SIX does not quietly empty the table.

A currency that leaves the list leaves the deck with the next release.
Amounts stored in it can no longer be rebuilt with `fromMinor`; convert them
before upgrading.
