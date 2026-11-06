# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.26.0

/**
 * White-box tests for the entry module: jennifer test src/money_test.j
 *
 * The overlay is compiled with its module, so it reaches unexported helpers.
 */
use testing;

def const MAX_INT as int init 9223372036854775807;

/**
 * The message a call fails with.
 *
 * @param f {func} a function taking nothing
 * @return {string} the message of the deck's error; "" when it passes
 */
func failure(f as func) {
    try {
        $f();
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
        return $e.message;
    }
    return "";
}

/**
 * The message `parse` fails with.
 *
 * @param text {string} the amount
 * @param code {string} the currency
 * @return {string} the message; "" when it parses
 */
func parseFailure(text as string, code as string) {
    try {
        parse($text, $code);
    } catch (e) {
        testing.assertEqual($e.kind, ERROR_KIND);
        return $e.message;
    }
    return "";
}

/**
 * The amounts of a list of parts.
 *
 * @param parts {list of Money} the parts
 * @return {list of int} their minor units
 */
func amounts(parts as list of Money) {
    def out as list of int init [];
    for (def p in $parts) {
        $out[] = $p.amount;
    }
    return $out;
}

func eur(amount as int) {
    return fromMinor($amount, "EUR");
}

func lowestInt() {
    return -MAX_INT - 1;
}

func addAcross() {
    add(eur(1), fromMinor(1, "USD"));
}

func compareAcross() {
    lessThan(eur(1), fromMinor(1, "USD"));
}

func sumAcross() {
    sum([eur(1), fromMinor(1, "USD")], "EUR");
}

func addPastMax() {
    add(eur(MAX_INT), eur(1));
}

func subtractPastMin() {
    subtract(eur(lowestInt()), eur(1));
}

func negateLowest() {
    negate(eur(lowestInt()));
}

func absoluteLowest() {
    absolute(eur(lowestInt()));
}

func multiplyPastMax() {
    multiply(eur(MAX_INT), "2", "half-even");
}

func lowerCaseCode() {
    fromMinor(1, "eur");
}

func unknownCode() {
    zero("ABC");
}

func unknownDigits() {
    digits("XAU");
}

func unknownMode() {
    multiply(eur(100), "2", "round");
}

func modeIsCaseSensitive() {
    fromDecimal(decimal.from("1"), "EUR", "HALF-UP");
}

func floatFactor() {
    multiply(eur(100), "1e2", "half-even");
}

func longFactor() {
    multiply(eur(100), "1." + strings.repeat("0", MAX_TEXT), "half-even");
}

func divideByZero() {
    divide(eur(100), "0.00", "half-even");
}

func negativeRatio() {
    allocate(eur(100), ["1", "-1"]);
}

func zeroRatios() {
    allocate(eur(100), ["0", "0.0"]);
}

func noRatios() {
    allocate(eur(100), []);
}

func tooManyParts() {
    allocateTo(eur(100), MAX_PARTS + 1);
}

func noParts() {
    allocateTo(eur(100), 0);
}

func zeroRate() {
    exchange(eur(100), "USD", "0", "half-even");
}

func negativeRate() {
    exchange(eur(100), "USD", "-1.08", "half-even");
}

func exchangeUnknown() {
    exchange(eur(100), "XXX", "1", "half-even");
}

func longCode() {
    fromMinor(1, strings.repeat("A", 1000000));
}

func longMode() {
    multiply(eur(1), "2", strings.repeat("x", 1000000));
}

func controlCode() {
    fromMinor(1, "E" + convert.fromCodepoint(10) + "R");
}

func controlAmount() {
    parse("1" + convert.fromCodepoint(27) + "[31m", "EUR");
}

func addZeroValues() {
    def z as Money;
    add($z, $z);
}

func negateMadeUp() {
    negate(Money{amount: 5, currency: "ZZZ"});
}

func allocateMadeUp() {
    allocateTo(Money{amount: 5, currency: "ZZZ"}, 2);
}

func multiplyMadeUp() {
    multiply(Money{amount: 5, currency: ""}, "2", "up");
}

func isZeroMadeUp() {
    isZero(Money{amount: 0, currency: ""});
}

func isNegativeMadeUp() {
    isNegative(Money{amount: -5, currency: "ZZZ"});
}

func isPositiveMadeUp() {
    isPositive(Money{amount: 5, currency: "ZZZ"});
}

func testMessagesAreBounded() {
    # A code or mode was echoed whole: a 1 MB string made a 1 MB message.
    testing.assertEqual(
        failure(longCode),
        "money: not a currency code: \"AAAAAAAAAAAAAAAAAAAA...\"");
    testing.assertEqual(
        failure(longMode),
        "money: unknown rounding mode \"xxxxxxxxxxxxxxxxxxxx...\"; use one of " +
            strings.join(MODES, ", "));
    # Control characters would reach a log line as they are.
    testing.assertEqual(failure(controlCode), "money: not a currency code: \"E?R\"");
    testing.assertEqual(
        failure(controlAmount),
        "money: amount is not a decimal number: \"1?[31m\"");
}

func testAmountsMustHaveAKnownCurrency() {
    # A zero-value or hand-built Money used to pass through arithmetic.
    testing.assertEqual(failure(addZeroValues), "money: not a currency code: \"\"");
    testing.assertEqual(failure(negateMadeUp), "money: unknown currency: ZZZ");
    testing.assertEqual(failure(allocateMadeUp), "money: unknown currency: ZZZ");
    testing.assertEqual(failure(multiplyMadeUp), "money: not a currency code: \"\"");
    testing.assertEqual(failure(isZeroMadeUp), "money: not a currency code: \"\"");
    testing.assertEqual(failure(isNegativeMadeUp), "money: unknown currency: ZZZ");
    testing.assertEqual(failure(isPositiveMadeUp), "money: unknown currency: ZZZ");
}

func testMaking() {
    testing.assertEqual(fromMinor(1234, "EUR"), Money{amount: 1234, currency: "EUR"});
    testing.assertEqual(zero("JPY"), Money{amount: 0, currency: "JPY"});
    testing.assertEqual(failure(lowerCaseCode), "money: not a currency code: \"eur\"");
    testing.assertEqual(failure(unknownCode), "money: unknown currency: ABC");
}

func testCurrencies() {
    testing.assertEqual(digits("JPY"), 0);
    testing.assertEqual(digits("EUR"), 2);
    testing.assertEqual(digits("KWD"), 3);
    testing.assertEqual(digits("CLF"), 4);
    testing.assertTrue(isCurrency("USD"));
    testing.assertFalse(isCurrency("usd"));
    # No minor units in the ISO list: gold, the testing and no-currency codes.
    testing.assertFalse(isCurrency("XAU"));
    testing.assertFalse(isCurrency("XTS"));
    testing.assertFalse(isCurrency("XXX"));
    testing.assertEqual(failure(unknownDigits), "money: unknown currency: XAU");
    def codes as list of string init currencies();
    testing.assertTrue(len($codes) > 150);
    testing.assertEqual($codes, lists.sort($codes));
    testing.assertEqual(lists.first($codes), "AED");
    testing.assertTrue(regex.matches("^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$", published()));
}

func testParse() {
    testing.assertEqual(parse("12.34", "EUR"), eur(1234));
    testing.assertEqual(parse("12.3", "EUR"), eur(1230));
    testing.assertEqual(parse("12", "EUR"), eur(1200));
    testing.assertEqual(parse("-0.05", "EUR"), eur(-5));
    testing.assertEqual(parse("-0", "EUR"), eur(0));
    testing.assertEqual(parse("12.340", "EUR"), eur(1234));
    testing.assertEqual(parse("007.50", "EUR"), eur(750));
    testing.assertEqual(parse("1200", "JPY"), fromMinor(1200, "JPY"));
    testing.assertEqual(parse("1200.000", "JPY"), fromMinor(1200, "JPY"));
    testing.assertEqual(parse("1.234", "KWD"), fromMinor(1234, "KWD"));
    testing.assertEqual(parse("92233720368547758.07", "EUR"), eur(MAX_INT));
    testing.assertEqual(
        parseFailure("12.345", "EUR"),
        "money: \"12.345\" has more than 2 decimal places for EUR");
    testing.assertEqual(
        parseFailure("1.5", "JPY"),
        "money: \"1.5\" has more than 0 decimal places for JPY");
    for (def bad in [
        "",
        "1e3",
        " 1",
        "1 ",
        "+1",
        "1,5",
        "1.",
        ".5",
        "--1",
        "1_000",
        "NaN",
        "Infinity",
        "٣"
    ]) {
        testing.assertEqual(
            parseFailure($bad, "EUR"),
            "money: amount is not a decimal number: " + shown($bad));
    }
    testing.assertEqual(parseFailure("92233720368547758.08", "EUR"), "money: amount out of range");
    testing.assertEqual(
        parseFailure(strings.repeat("1", MAX_TEXT + 1), "EUR"),
        "money: amount longer than 50 characters");
    testing.assertEqual(parseFailure("1", "XAU"), "money: unknown currency: XAU");
}

func testFormat() {
    testing.assertEqual(format(eur(1234)), "12.34");
    testing.assertEqual(format(eur(500)), "5.00");
    testing.assertEqual(format(eur(-5)), "-0.05");
    testing.assertEqual(format(eur(0)), "0.00");
    testing.assertEqual(format(fromMinor(1200, "JPY")), "1200");
    testing.assertEqual(format(fromMinor(1, "KWD")), "0.001");
    testing.assertEqual(format(fromMinor(-1, "CLF")), "-0.0001");
    testing.assertEqual(format(eur(MAX_INT)), "92233720368547758.07");
    testing.assertEqual(format(eur(lowestInt())), "-92233720368547758.08");
    # format and parse are inverses.
    for (def code in ["EUR", "JPY", "KWD", "CLF"]) {
        for (def n in [0, 1, -1, 7, 1000, -123456, MAX_INT, lowestInt()]) {
            testing.assertEqual(parse(format(fromMinor($n, $code)), $code), fromMinor($n, $code));
        }
    }
}

func testDecimals() {
    testing.assertEqual(decimal.toString(toDecimal(eur(1200))), "12.00");
    testing.assertEqual(decimal.toString(toDecimal(fromMinor(5, "JPY"))), "5");
    testing.assertEqual(fromDecimal(decimal.from("12.345"), "EUR", "half-even"), eur(1234));
    testing.assertEqual(fromDecimal(decimal.from("12.345"), "EUR", "half-up"), eur(1235));
    testing.assertEqual(fromDecimal(decimal.from("-12.345"), "EUR", "floor"), eur(-1235));
    testing.assertEqual(fromDecimal(decimal.from("2.5"), "JPY", "half-even"), fromMinor(2, "JPY"));
    testing.assertEqual(
        failure(modeIsCaseSensitive),
        "money: unknown rounding mode \"HALF-UP\"; use one of " + strings.join(MODES, ", "));
}

func testArithmetic() {
    testing.assertEqual(add(eur(150), eur(-50)), eur(100));
    testing.assertEqual(subtract(eur(150), eur(200)), eur(-50));
    testing.assertEqual(sum([eur(1), eur(2), eur(3)], "EUR"), eur(6));
    testing.assertEqual(sum([], "KWD"), fromMinor(0, "KWD"));
    testing.assertEqual(negate(eur(5)), eur(-5));
    testing.assertEqual(absolute(eur(-5)), eur(5));
    testing.assertEqual(absolute(eur(5)), eur(5));
    testing.assertEqual(add(eur(MAX_INT - 1), eur(1)), eur(MAX_INT));
    testing.assertEqual(subtract(eur(-MAX_INT), eur(1)), eur(lowestInt()));
    # The running total may leave the int range as long as the result does not.
    testing.assertEqual(sum([eur(MAX_INT), eur(1), eur(-1)], "EUR"), eur(MAX_INT));
    testing.assertEqual(failure(addAcross), "money: different currencies: EUR and USD");
    testing.assertEqual(failure(sumAcross), "money: different currencies: EUR and USD");
    testing.assertEqual(failure(addPastMax), "money: amount out of range");
    testing.assertEqual(failure(subtractPastMin), "money: amount out of range");
    testing.assertEqual(failure(negateLowest), "money: amount out of range");
    testing.assertEqual(failure(absoluteLowest), "money: amount out of range");
}

func testMultiplyAndDivide() {
    testing.assertEqual(multiply(eur(1999), "1.19", "half-up"), eur(2379));
    testing.assertEqual(multiply(eur(1999), "3", "half-even"), eur(5997));
    testing.assertEqual(multiply(eur(100), "-0.5", "half-even"), eur(-50));
    testing.assertEqual(multiply(eur(100), "0", "up"), eur(0));
    # 0.5 of 5 cents is 2.5 cents: every mode on both signs.
    def ups as list of int init [];
    def downs as list of int init [];
    for (def mode in MODES) {
        $ups[] = multiply(eur(5), "0.5", $mode).amount;
        $downs[] = multiply(eur(-5), "0.5", $mode).amount;
    }
    testing.assertEqual($ups, [2, 3, 2, 3, 2, 3, 2]);
    testing.assertEqual($downs, [-2, -3, -2, -3, -2, -2, -3]);
    testing.assertEqual(divide(eur(1000), "3", "half-even"), eur(333));
    testing.assertEqual(divide(eur(1000), "3", "up"), eur(334));
    testing.assertEqual(divide(eur(-1000), "3", "floor"), eur(-334));
    testing.assertEqual(divide(eur(119), "1.19", "half-even"), eur(100));
    testing.assertEqual(divide(fromMinor(1000, "KWD"), "8", "half-even"), fromMinor(125, "KWD"));
    testing.assertEqual(failure(divideByZero), "money: division by zero");
    testing.assertEqual(
        failure(unknownMode),
        "money: unknown rounding mode \"round\"; use one of " + strings.join(MODES, ", "));
    testing.assertEqual(failure(floatFactor), "money: factor is not a decimal number: \"1e2\"");
    testing.assertEqual(failure(longFactor), "money: factor longer than 50 characters");
    testing.assertEqual(failure(multiplyPastMax), "money: amount out of range");
}

func testAllocate() {
    testing.assertEqual(amounts(allocate(eur(1000), ["1", "1", "1"])), [334, 333, 333]);
    testing.assertEqual(amounts(allocate(eur(5), ["70", "30"])), [4, 1]);
    testing.assertEqual(amounts(allocate(eur(5), ["0.7", "0.3"])), [4, 1]);
    testing.assertEqual(amounts(allocate(eur(5), ["7", "0.3"])), [5, 0]);
    testing.assertEqual(amounts(allocate(eur(-5), ["70", "30"])), [-4, -1]);
    testing.assertEqual(amounts(allocate(eur(0), ["1", "2"])), [0, 0]);
    testing.assertEqual(amounts(allocate(eur(100), ["0", "1", "0"])), [0, 100, 0]);
    # The leftover goes to the largest remainders, not to the first parts:
    # 10 by 1:1:3 is 2, 2, 6 exactly; 11 is 2.2, 2.2, 6.6 and gets 2, 2, 7.
    testing.assertEqual(amounts(allocate(eur(11), ["1", "1", "3"])), [2, 2, 7]);
    testing.assertEqual(amounts(allocate(eur(2), ["1", "1", "1"])), [1, 1, 0]);
    # A zero ratio never gets the leftover, even when it comes first.
    testing.assertEqual(amounts(allocate(eur(1), ["0", "1", "1"])), [0, 1, 0]);
    def parts as list of Money init allocate(eur(lowestInt()), ["1", "1"]);
    testing.assertEqual(sum($parts, "EUR"), eur(lowestInt()));
    testing.assertEqual(lists.first($parts).currency, "EUR");
    testing.assertEqual(failure(negativeRatio), "money: negative ratio: -1");
    testing.assertEqual(failure(zeroRatios), "money: every ratio is zero");
    testing.assertEqual(failure(noRatios), "money: nothing to allocate to");
}

func testAllocateTo() {
    testing.assertEqual(amounts(allocateTo(eur(1000), 3)), [334, 333, 333]);
    testing.assertEqual(amounts(allocateTo(eur(-1000), 3)), [-334, -333, -333]);
    testing.assertEqual(amounts(allocateTo(eur(2), 4)), [1, 1, 0, 0]);
    testing.assertEqual(amounts(allocateTo(eur(7), 1)), [7]);
    testing.assertEqual(
        amounts(allocateTo(eur(MAX_INT), 2)),
        [4611686018427387904, 4611686018427387903]);
    testing.assertEqual(failure(noParts), "money: nothing to allocate to");
    testing.assertEqual(failure(tooManyParts), "money: more than 100000 parts");
}

func testAllocationNeverLosesAUnit() {
    # A small linear congruential generator, so the cases are the same on
    # every run.
    def seed as int init 12345;
    for (def round as int init 0; $round < 200; $round = $round + 1) {
        $seed = ($seed * 1103515245 + 12345) % 2147483648;
        def amount as int init $seed % 100000 - 50000;
        def n as int init $seed % 7 + 1;
        def ratios as list of string init [];
        for (def i as int init 0; $i < $n; $i = $i + 1) {
            $seed = ($seed * 1103515245 + 12345) % 2147483648;
            $ratios[] = convert.toString($seed % 1000) + "." + convert.toString($seed % 10);
        }
        def parts as list of Money init allocate(eur($amount), $ratios);
        testing.assertEqual(len($parts), $n);
        testing.assertEqual(sum($parts, "EUR"), eur($amount));
        def even as list of Money init allocateTo(eur($amount), $n);
        testing.assertEqual(sum($even, "EUR"), eur($amount));
        def spread as int init lists.first($even).amount - lists.last($even).amount;
        testing.assertTrue($spread == 0 or $spread == 1 or $spread == -1);
    }
}

func testManyParts() {
    # Appending with lists.push copied the list each time: 10000 parts took
    # 69 s and MAX_PARTS would have taken hours. Now about 2 s.
    def parts as list of Money init allocateTo(eur(123456789), MAX_PARTS);
    testing.assertEqual(len($parts), MAX_PARTS);
    testing.assertEqual(lists.first($parts).amount, 1235);
    testing.assertEqual(lists.last($parts).amount, 1234);
    testing.assertEqual(sum($parts, "EUR"), eur(123456789));
}

func testExchange() {
    testing.assertEqual(
        exchange(eur(10000), "USD", "1.0832", "half-even"),
        fromMinor(10832, "USD"));
    testing.assertEqual(
        exchange(eur(10000), "JPY", "162.345", "half-even"),
        fromMinor(16234, "JPY"));
    testing.assertEqual(exchange(eur(10000), "JPY", "162.345", "up"), fromMinor(16235, "JPY"));
    testing.assertEqual(
        exchange(fromMinor(16234, "JPY"), "KWD", "0.00203", "half-even"),
        fromMinor(32955, "KWD"));
    testing.assertEqual(exchange(fromMinor(1, "KWD"), "EUR", "2.9", "half-even"), eur(0));
    testing.assertEqual(exchange(fromMinor(1, "KWD"), "EUR", "2.9", "up"), eur(1));
    testing.assertEqual(exchange(eur(-100), "USD", "1.5", "half-even"), fromMinor(-150, "USD"));
    testing.assertEqual(failure(zeroRate), "money: rate must be above zero: 0");
    testing.assertEqual(failure(negativeRate), "money: rate must be above zero: -1.08");
    testing.assertEqual(failure(exchangeUnknown), "money: unknown currency: XXX");
}

func testComparing() {
    testing.assertEqual(compare(eur(1), eur(2)), -1);
    testing.assertEqual(compare(eur(2), eur(2)), 0);
    testing.assertEqual(compare(eur(3), eur(2)), 1);
    testing.assertTrue(lessThan(eur(-1), eur(0)));
    testing.assertFalse(lessThan(eur(0), eur(0)));
    testing.assertTrue(greaterThan(eur(1), eur(0)));
    testing.assertTrue(isZero(zero("EUR")));
    testing.assertTrue(isNegative(eur(-1)));
    testing.assertFalse(isNegative(eur(0)));
    testing.assertTrue(isPositive(eur(1)));
    testing.assertFalse(isPositive(eur(0)));
    testing.assertTrue(eur(5) == parse("0.05", "EUR"));
    testing.assertFalse(eur(5) == fromMinor(5, "USD"));
    testing.assertEqual(failure(compareAcross), "money: different currencies: EUR and USD");
}
