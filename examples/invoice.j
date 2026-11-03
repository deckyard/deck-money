# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * An invoice: lines, VAT, a three-way split and the total in another
 * currency.
 *
 *   jennifer run examples/invoice.j
 */
use io;

import "../src/money.j" as money;

def lines as list of money.Money init [
    money.multiply(money.parse("19.99", "EUR"), "3", "half-even"),
    money.multiply(money.parse("4.50", "EUR"), "2", "half-even"),
    money.parse("0.99", "EUR")
];
def net as money.Money init money.sum($lines, "EUR");
def vat as money.Money init money.multiply($net, "0.20", "half-up");
def gross as money.Money init money.add($net, $vat);
io.printf(
    "net %s + VAT %s = %s EUR\n",
    money.format($net),
    money.format($vat),
    money.format($gross));

io.printf("split three ways:");
for (def part in money.allocateTo($gross, 3)) {
    io.printf(" %s", money.format($part));
}
io.printf("\n");

def yen as money.Money init money.exchange($gross, "JPY", "162.345", "half-even");
io.printf("in JPY at 162.345: %s\n", money.format($yen));
