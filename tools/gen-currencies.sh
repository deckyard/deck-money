#!/usr/bin/env bash
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
#
# Regenerate src/currencies.j from the current ISO 4217 list.
#
# SIX maintains the list for ISO and publishes it as list-one.xml. The list is
# downloaded to a temporary file, not kept in the repository; the generated
# table records its publication date. Review the diff, then release.
#
# Usage: tools/gen-currencies.sh [list-one.xml]
#   With a file, use it instead of downloading.
set -euo pipefail
cd "$(dirname "$0")/.."

URL="https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml"

if [[ $# -ge 1 ]]; then
    list="$1"
else
    list="$(mktemp --suffix=.xml)"
    trap 'rm -f -- "$list"' EXIT
    curl -sSfL --max-time 60 --max-filesize 10000000 -o "$list" "$URL"
fi

jennifer run tools/gen-currencies.j "$list" src/currencies.j
jennifer fmt -w src/currencies.j
