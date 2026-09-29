.PHONY: setup run run-headoverheels run-knightlore serve-headoverheels serve-knightlore serve-editor run-editor build-headoverheels build-knightlore build-editor test test-packages test-coverage lint format format-check check assets-check doctor help build build-release build-release-apk build-release-appbundle build-release-all build-version generate clean security-scan install

# The repository holds two games and three libraries. Nothing at the top level is
# a package of its own, so every command names the directory it runs in.
GAMES := games/headoverheels games/knightlore
LIBRARIES := packages/iso_core packages/iso_editor
GAME := games/headoverheels

AES_LANGUAGE ?= flutter
AES_LINT ?= flutter analyze --no-fatal-infos --no-fatal-warnings
AES_TEST ?= flutter test
AES_FORMAT ?= dart format games packages
AES_BUILD ?= flutter build apk --release
AES_RUN ?= flutter run -d web-server

export AES_LANGUAGE AES_LINT AES_TEST AES_FORMAT AES_BUILD AES_RUN

setup:
	@echo "Setting up $(AES_LANGUAGE)..."
	@for dir in $(GAMES) $(LIBRARIES); do (cd $$dir && flutter pub get) || exit 1; done
	@cd packages/iso_builder_cli && dart pub get

run: run-headoverheels

run-headoverheels:
	@cd $(GAME) && $(AES_RUN) --web-port 8080

run-knightlore:
	@cd games/knightlore && $(AES_RUN) --web-port 8081

# Serves a game's web build the way a player would load it.
#
# `make run-<game>` is for working on the game: it serves a *debug* build, where
# the whole program is compiled in the browser as it loads, which is why running
# Knight Lore that way leaves a person on "Loading the castle" for minutes. These
# build first and serve the result, so what is on the screen is the game.
#
# The server is a foreground process: Ctrl-C stops it. The ports are the same ones
# `make run-<game>` uses, so the two cannot both be up at once.
serve: serve-headoverheels

serve-headoverheels:
	@$(MAKE) build-headoverheels
	@echo "Head over Heels, release build: http://localhost:8080 (Ctrl-C to stop)"
	@cd games/headoverheels/build/web && python3 -m http.server 8080

serve-knightlore:
	@$(MAKE) build-knightlore
	@echo "Knight Lore, release build: http://localhost:8081 (Ctrl-C to stop)"
	@cd games/knightlore/build/web && python3 -m http.server 8081

# The editor is a library that has an entry point, so it builds and serves like a
# game. Its map lives in the page: it can read and write Tiled files through the
# file gateway, and it keeps nothing between visits.
build-editor:
	@cd packages/iso_editor && flutter build web

run-editor:
	@cd packages/iso_editor && $(AES_RUN) --web-port 8082

serve-editor:
	@$(MAKE) build-editor
	@echo "Iso Editor, release build: http://localhost:8082 (Ctrl-C to stop)"
	@cd packages/iso_editor/build/web && python3 -m http.server 8082

build-headoverheels:
	@cd $(GAME) && flutter build web

build-knightlore:
	@cd games/knightlore && flutter build web

test:
	@cd $(GAME) && $(AES_TEST)

lint:
	@cd $(GAME) && $(AES_LINT)

format:
	@$(AES_FORMAT)

format-check:
	@dart format --output=none --set-exit-if-changed games packages

check: format-check lint test test-packages assets-check

test-packages:
	@cd packages/iso_core && flutter test
	@cd packages/iso_editor && flutter test
	@cd packages/iso_builder_cli && dart test
	@cd games/knightlore && flutter test

assets-check:
	@python3 scripts/validation_pipeline.py $(GAME)
	@python3 scripts/validate_sprites.py $(GAME)
	@python3 scripts/publish_planet_tilesets.py --check
	@for game in $(GAMES); do python3 scripts/publish_assets.py $$game --check || exit 1; done

build:
	@cd $(GAME) && $(AES_BUILD)

# Release builds
build-release-apk:
	@echo "Building release APK..."
	@cd $(GAME) && flutter build apk --release --obfuscate --split-debug-info=build/debug_info

build-release-appbundle:
	@echo "Building release App Bundle (for Play Store)..."
	@cd $(GAME) && flutter build appbundle --release --obfuscate --split-debug-info=build/debug_info

build-release-all: build-release-appbundle build-release-apk

# Build with version from pubspec
build-version:
	@cd $(GAME) && flutter build apk --release --obfuscate --split-debug-info=build/debug_info --build-name=$$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1) --build-number=$$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f2)

# Clean build artifacts
clean:
	@for dir in $(GAMES) $(LIBRARIES); do (cd $$dir && flutter clean) || exit 1; done
	@rm -rf packages/iso_builder_cli/build/
	@rm -rf build/ .dart_tool/
	@rm -rf $(GAME)/android/.gradle/ $(GAME)/android/app/build/

# Run code generation
generate:
	@cd $(GAME) && dart run build_runner build --delete-conflicting-outputs

# Run tests with coverage
test-coverage:
	@cd $(GAME) && flutter test --coverage
	@genhtml $(GAME)/coverage/lcov.info -o coverage/html

# Check for security issues
security-scan:
	@cd $(GAME) && $(AES_LINT)
	@echo "Checking for hardcoded secrets..."
	@! grep -r "password\|secret\|api_key" $(GAME)/lib/ --include="*.dart" | grep -v "YOUR_" | grep -v "// " || echo "Potential secrets found!"

# Install on connected device
install:
	@cd $(GAME) && flutter install --release

# Doctor check
doctor:
	@echo "Language: $(AES_LANGUAGE)"
	@echo "Flutter: $$(flutter --version 2>/dev/null | head -1 || echo not-found)"

# Help
help:
	@echo "AES Commands:"
	@echo "  make setup           - Install dependencies"
	@echo "  make run             - Run in debug mode"
	@echo "  make test            - Run tests"
	@echo "  make test-coverage   - Run tests with coverage"
	@echo "  make lint            - Run analyzer"
	@echo "  make format          - Format code"
	@echo "  make build           - Build debug APK"
	@echo "  make build-release-apk      - Build release APK"
	@echo "  make build-release-appbundle - Build release App Bundle (Play Store)"
	@echo "  make build-release-all      - Build both APK and App Bundle"
	@echo "  make build-version  - Build with version from pubspec"
	@echo "  make generate        - Run code generation"
	@echo "  make clean           - Clean build artifacts"
	@echo "  make security-scan   - Check for security issues"
	@echo "  make install         - Install release APK on device"
	@echo "  make doctor          - Show environment info"
	@echo "  make format-check    - Verify Dart formatting"
	@echo "  make test-packages   - Test builder packages"
	@echo "  make assets-check    - Validate sprite assets"
	@echo "  make check           - Run all checks"