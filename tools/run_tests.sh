#!/usr/bin/env bash
# Flex + Bison Parser Test Runner
# Usage: bash tools/run_tests.sh [--update]
#
#   (no args)  Run tests, compare against expected/ snapshots
#   --update   Regenerate expected/ snapshots from current parser output
#              Also auto-generates on first run when no snapshot exists.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
PARSER="$WORKSPACE/parser"
INPUT_DIR="$WORKSPACE/testing/input"
EXPECTED_DIR="$WORKSPACE/testing/expected"

UPDATE_MODE=false
[ "${1:-}" = "--update" ] && UPDATE_MODE=true

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
GENERATED=0

# Normalize for comparison:
#   1. Strip leading token index (e.g. "42: TOKEN:" -> "TOKEN:")
#   2. Collapse runs of spaces/tabs to a single space
#   3. Strip leading/trailing space per line
normalize() {
    sed \
        -e 's/^[0-9]\+: //' \
        -e 's/[[:space:]]\+/ /g' \
        -e 's/^ //' \
        -e 's/ $//' \
        "$@"
}

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Flex + Bison Parser Test Suite${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

if [ ! -f "$PARSER" ]; then
    echo -e "${RED}ERROR: parser binary not found at: $PARSER${NC}"
    echo "Build first with:  make -f tools/Makefile build-parser"
    exit 1
fi

mkdir -p "$EXPECTED_DIR"

for input_file in "$INPUT_DIR"/test*.txt; do
    [ -f "$input_file" ] || { echo -e "${YELLOW}No test input files found in $INPUT_DIR${NC}"; break; }
    test_name="$(basename "$input_file" .txt)"
    expected_file="$EXPECTED_DIR/${test_name}.expected"

    actual_output="$("$PARSER" < "$input_file" 2>&1)"

    if $UPDATE_MODE || [ ! -f "$expected_file" ]; then
        printf '%s\n' "$actual_output" > "$expected_file"
        echo -e "  [${test_name}]  ${YELLOW}GENERATED${NC}"
        GENERATED=$((GENERATED + 1))
    else
        # Compare with whitespace normalization (assignment spec: whitespace ignored)
        if diff -q \
            <(printf '%s\n' "$actual_output" | normalize) \
            <(normalize "$expected_file") \
            > /dev/null 2>&1; then
            echo -e "  [${test_name}]  ${GREEN}PASS${NC}"
            PASS=$((PASS + 1))
        else
            echo -e "  [${test_name}]  ${RED}FAIL${NC}"
            echo ""
            echo "    Expected:"
            normalize "$expected_file" | sed 's/^/      /'
            echo ""
            echo "    Actual:"
            printf '%s\n' "$actual_output" | normalize | sed 's/^/      /'
            echo ""
            echo "    Diff (< expected  > actual):"
            diff \
                <(normalize "$expected_file") \
                <(printf '%s\n' "$actual_output" | normalize) \
                | sed 's/^/      /' || true
            echo ""
            FAIL=$((FAIL + 1))
        fi
    fi
done

echo ""
echo -e "${BLUE}================================================${NC}"
[ $GENERATED -gt 0 ] && echo -e "  ${YELLOW}Generated: $GENERATED${NC}  (re-run to compare)"
[ $((PASS + FAIL)) -gt 0 ] && echo -e "  ${GREEN}Passed:    $PASS${NC}"
[ $FAIL -gt 0 ]            && echo -e "  ${RED}Failed:    $FAIL${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Tip on first run
if [ $GENERATED -gt 0 ]; then
    echo -e "${YELLOW}Tip:${NC} Expected snapshots were just created."
    echo "     Run 'make -f tools/Makefile test' again to verify."
    echo "     To regenerate snapshots: make -f tools/Makefile test-update"
    echo ""
fi

[ $FAIL -eq 0 ]
