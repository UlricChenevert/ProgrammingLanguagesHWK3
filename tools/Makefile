# Flex/Bison Project Makefile
# Must be run from workspace root: make -f tools/Makefile [target]

CXX      = g++
FLEX     = flex
BISON    = bison
CXXFLAGS = -Wall

# Source files (workspace root)
LEX_SRC    = TokenSpec.l
PARSER_SRC = ParserSpec.y

# Generated intermediates
LEX_C    = lex.yy.c
PARSER_C = parser.tab.c
PARSER_H = parser.tab.h

# Output binaries
LEXER_BIN  = lexer
PARSER_BIN = parser

.PHONY: all build-lexer build-parser clean test test-update

all: build-lexer

# ── Standalone lexer ─────────────────────────────────────────────
build-lexer: $(LEXER_BIN)

$(LEXER_BIN): $(LEX_SRC)
	$(FLEX) $(LEX_SRC)
	$(CXX) $(CXXFLAGS) -o $(LEXER_BIN) $(LEX_C)

# ── Flex + Bison parser ──────────────────────────────────────────
build-parser: $(PARSER_BIN)

$(PARSER_BIN): $(PARSER_SRC) $(LEX_SRC)
	$(BISON) -d $(PARSER_SRC) -o $(PARSER_C)
	$(FLEX) $(LEX_SRC)
	$(CXX) $(CXXFLAGS) -o $(PARSER_BIN) $(PARSER_C) $(LEX_C)

# ── Test targets ─────────────────────────────────────────────────
test: $(PARSER_BIN)
	@bash tools/run_tests.sh

test-update: $(PARSER_BIN)
	@bash tools/run_tests.sh --update

# ── Cleanup ──────────────────────────────────────────────────────
clean:
	rm -f $(LEX_C) $(LEXER_BIN) $(PARSER_C) $(PARSER_H) $(PARSER_BIN)
