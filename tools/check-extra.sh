#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
#
# src/currencies.j is generated from the ISO 4217 list, which is downloaded,
# not kept here. Run the generator on the sample in testdata/iso4217 and
# compare with the table it must produce, so a change to the generator is
# tested without the network.
#
# Usage: tools/check-extra.sh
set -euo pipefail
cd "$(dirname "$0")/.."

JENNIFER="${JENNIFER:-jennifer}"

# Inside the checkout, not /tmp: in CI the interpreter runs in a container
# that sees only the checkout.
out="testdata/iso4217/.generated.j"
trap 'rm -f -- "$out"' EXIT

$JENNIFER run tools/gen-currencies.j testdata/iso4217/list-one.xml "$out" 1
$JENNIFER fmt -w "$out"

if ! diff -u testdata/iso4217/expected.j "$out"; then
    echo "::error::tools/gen-currencies.j no longer makes testdata/iso4217/expected.j" >&2
    exit 1
fi
echo "the currency generator makes the expected table"
