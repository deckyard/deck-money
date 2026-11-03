# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * Tests for the generated table: jennifer test src/currencies_test.j
 */
use maps;
use regex;
use testing;

func testTheTableIsWellFormed() {
    testing.assertTrue(len(DIGITS) > 150);
    for (def code in maps.keys(DIGITS)) {
        testing.assertTrue(regex.matches("^[A-Z]\{3\}$", $code));
        testing.assertTrue(DIGITS[$code] >= 0 and DIGITS[$code] <= 4);
    }
    testing.assertTrue(regex.matches("^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$", PUBLISHED));
}

func testKnownCurrencies() {
    testing.assertEqual(DIGITS["EUR"], 2);
    testing.assertEqual(DIGITS["USD"], 2);
    testing.assertEqual(DIGITS["JPY"], 0);
    testing.assertEqual(DIGITS["ISK"], 0);
    testing.assertEqual(DIGITS["KWD"], 3);
    testing.assertEqual(DIGITS["BHD"], 3);
    testing.assertEqual(DIGITS["CLF"], 4);
    testing.assertFalse(maps.has(DIGITS, "XAU"));
    testing.assertFalse(maps.has(DIGITS, "XXX"));
}
