<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Design

## Scope

The deck holds currency amounts exactly and does the arithmetic money needs:
adding and summing in one currency, multiplying and dividing by a factor,
splitting an amount without losing a minor unit, exchanging at a given rate,
and reading and writing amounts as plain text. It is pure computation: no
I/O at run time, no capabilities.

It is a deck rather than part of the interpreter because the currency table
is data that changes (ISO 4217 is amended a few times a year) and because
money rules (allocation, rounding policy, display) vary by application. The
interpreter keeps the general primitive, exact decimal arithmetic in the
`decimal` library, and the deck builds on it.

Deliberately out of scope:

- **Exchange-rate fetching.** It would need the `net` capability and tie the
  deck to one rates provider. The caller fetches rates from a source it
  trusts and passes them to `exchange`.
- **Locale-aware formatting** (digit grouping, the decimal comma, symbol
  placement). It is an open question for the language's own formatting, and a
  deck should not settle it first. `format` writes a plain dot-separated
  number.
- **Custom currencies** (crypto, loyalty points). They would put the number
  of places on each `Money` and change equality and storage.
- **A JSON shape.** `Money` is two plain fields; a caller serialises it as it
  likes.
- **Financial maths** (interest, loans, day counts). That is the planned
  `finance` deck, which would build on this one.

## Decisions

- **Amounts are whole minor units in an `int`.** `Money{amount, currency}`
  stores 12.34 EUR as `1234`, as moneyphp does. Every amount is exact by
  construction, compares and sorts as an `int`, and `==` is already correct,
  so there is no `equals`. An `int` covers about 9.2 x 10^16 minor units,
  ample for any single amount.
- **Overflow is a deck error.** All arithmetic, including `add`, `subtract`,
  `negate` and `absolute`, goes through `decimal` and comes back through one
  checked conversion, so a result past the `int` range throws
  `money: amount out of range` instead of wrapping. `sum` keeps a decimal
  running total, so intermediate totals may leave the `int` range as long as
  the result does not.
- **No float touches an amount.** Factors, rates and ratios are decimal
  strings such as `"1.19"`, parsed exactly through `decimal`. A string rather
  than a `Decimal` parameter because Jennifer has no union parameter type and
  a `Decimal` turns into exact text with `decimal.toString`. `toDecimal` and
  `fromDecimal` bridge to the `decimal` library for callers who compute there.
- **Rounding is always explicit.** `multiply`, `divide`, `exchange` and
  `fromDecimal` take a mode from `MODES`, the seven names the `decimal`
  library uses, case-sensitive. There is no default mode anywhere: the right
  one depends on the application (tax, invoicing, banking), so the caller
  states it.
- **Currencies never mix.** `add`, `subtract`, `sum`, `compare`, `lessThan`
  and `greaterThan` refuse amounts in different currencies. Exchange is a
  separate, explicit step. It is named `exchange` because the deck itself
  uses the `convert` library.
- **Every `Money` is validated.** Each export that takes or returns a `Money`
  checks the code's shape (three upper-case letters) and that it is in the
  table, even `negate`, `absolute`, `isZero`, `isNegative` and `isPositive`.
  A hand-built or zero-value `Money` with an empty or unknown currency is
  rejected, not passed through. An unknown code is an error, never a guess.
- **Allocation never loses or creates a unit.** `allocate(m, ratios)` and
  `allocateTo(m, n)` share one largest-remainder core: each share is rounded
  down, and the leftover minor units go one each to the largest remainders,
  the earlier part on a tie. A part with weight zero never receives a
  leftover unit. Decimal ratios are scaled to whole weights first, so
  `["0.7", "0.3"]` behaves like `["7", "3"]`. Ratios must not be negative or
  all zero. A negative amount splits as the mirror of its absolute value.
- **`exchange` rounds once.** It multiplies by the rate, rescales between the
  two currencies' minor units, and rounds a single time in the caller's mode.
  The rate must be above zero.
- **Strict text.** `parse` takes `-?digits(.digits)?` only: no `+`, exponent,
  spaces or digit separators. It refuses more places than the currency has
  unless the extra digits are zeros (`"12.340"` is accepted for EUR,
  `"12.345"` is not). `format` writes no grouping, symbol or code and is the
  exact inverse of `parse`.
- **The currency table is generated into the source.** `src/currencies.j`
  holds `PUBLISHED` (the list's date) and the code-to-places table, generated
  from the ISO 4217 list SIX™ publishes (`list-one.xml`) by
  `tools/gen-currencies.j`, a Jennifer script over the `xml` library. The
  deck needs no data file at run time, and a table update is
  regenerate-review-release. Codes the list gives no minor units (precious
  metals, `XTS`, `XXX`) are left out; fund codes such as `CLF` (4 places) are
  in. `isCurrency`, `digits`, `currencies` and `published` read the table.
- **One module.** The deck is small enough to be a single entry module plus
  the generated table; there is no `src/topics/`.

## Errors

Every failure is `Error{kind: "money"}` (`ERROR_KIND`) with a message that
starts `money: `, except a reached cap (below). The deck calls no server, so there is no error struct with
status fields. Callers tell failures apart by the kind only; messages are for
people.

A reached cap is the generic kind `"limit"`, with the same `money: `
prefix: a string longer than `MAX_TEXT` characters, or more than
`MAX_PARTS` parts. Before 0.2.0 these were kind `"money"` too.

## Security and limits

The deck treats every string a caller passes as possibly hostile:

- Factor, rate, ratio and amount strings are at most `MAX_TEXT` (50)
  characters, so a hostile string cannot become a huge number for `decimal`
  to work on.
- An allocation has at most `MAX_PARTS` (100000) parts.
- Error messages are bounded: a caller's string is cut to 20 characters plus
  `...`, and anything outside printable ASCII is replaced by `?`. Before this
  a 1 MB code made a 1 MB message, and control characters reached logs.
- The generator refuses a list with fewer than 100 currencies, a bad date, a
  malformed code or conflicting minor units, so a change of format at SIX
  cannot quietly empty or corrupt the table.

## Testing and validation

- `src/money_test.j` covers every export, the rounding modes, overflow at
  the `int` edges, allocation and the bounded messages. Failure messages are
  asserted verbatim. A property test splits random amounts with a fixed-seed
  generator and checks that no unit is ever lost, so it is deterministic. The
  slowest test allocates `MAX_PARTS` parts.
- `src/currencies_test.j` checks the table's shape and known entries (EUR 2,
  JPY 0, KWD 3, CLF 4, no XAU or XXX).
- `tools/check-extra.sh` runs the generator offline on a stored
  `testdata/iso4217/list-one.xml` and compares its formatted output with
  `testdata/iso4217/expected.j`.
- `examples/invoice.j` runs in the gate.

Nothing is tested against another money library's results; the expected
values are worked out by hand.

## Known limitations and open questions

- A currency that leaves the ISO 4217 list leaves the deck with the next
  release, and amounts stored in it can no longer be rebuilt with
  `fromMinor`. The diff of `src/currencies.j` needs review before every
  release.
- The generator writes the file's header lines itself, so a change of
  licence or floor in `deck.toml` has to be made in the generator and in
  `testdata/iso4217/expected.j` too.
- Locale-aware display waits for the language's decision on locale-aware
  value formatting.

## Dependencies on the interpreter

- The `decimal` system library (exact base-10 arithmetic and its seven
  rounding modes), first shipped in 0.26.0, in both `jennifer` and
  `jennifer-tiny`.
- Floor `>=0.28.0` (the calls 0.29.0 removes are replaced by their 0.28.0 forms) for both binaries: `strings.replicate` arrived in
  0.27.0.
- The `$list[] = x` append in allocation loops: appending with `lists.push`
  copied the list each time and made large allocations quadratic.
