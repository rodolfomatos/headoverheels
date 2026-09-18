.PHONY: setup run test lint format build check doctor help

AES_LANGUAGE ?= flutter
AES_LINT ?= flutter analyze
AES_TEST ?= flutter test
AES_FORMAT ?= dart format .
AES_BUILD ?= flutter build apk --release
AES_RUN ?= flutter run

export AES_LANGUAGE AES_LINT AES_TEST AES_FORMAT AES_BUILD AES_RUN

setup:
	@echo "Setting up $(AES_LANGUAGE)..."
	flutter pub get

run:
	@$(AES_RUN)

test:
	@$(AES_TEST)

lint:
	@$(AES_LINT)

format:
	@$(AES_FORMAT)

build:
	@$(AES_BUILD)

check: docs-check code-check test-check lint-check

docs-check:
	@test -f docs/VISION.md && grep -q "Problem" docs/VISION.md
	@test -f docs/PERSONAS.md && grep -q "User" docs/PERSONAS.md
	@test -f docs/REQUIREMENTS.md && grep -q "Functional" docs/REQUIREMENTS.md
	@test -f docs/ROADMAP.md && grep -q "Roadmap" docs/ROADMAP.md

code-check:
	@test -d lib
	@grep -R "TODO:" lib/ 2>/dev/null || true

test-check:
	@$(AES_TEST)

lint-check:
	@$(AES_LINT)

validate:
	@flutter analyze 2>&1 || true

doctor:
	@echo "Language: $(AES_LANGUAGE)"
	@echo "Flutter: $$(flutter --version 2>/dev/null | head -1 || echo not-found)"

help:
	@echo "AES Commands: make setup run test lint format build check doctor"
