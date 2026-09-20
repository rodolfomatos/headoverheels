.PHONY: setup run test lint format build build-release check doctor help

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

# Release builds
build-release-apk:
	@echo "Building release APK..."
	flutter build apk --release --obfuscate --split-debug-info=build/debug_info

build-release-appbundle:
	@echo "Building release App Bundle (for Play Store)..."
	flutter build appbundle --release --obfuscate --split-debug-info=build/debug_info

build-release-all: build-release-appbundle build-release-apk

# Build with version from pubspec
build-version:
	@flutter build apk --release --obfuscate --split-debug-info=build/debug_info --build-name=$$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1) --build-number=$$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f2)

# Clean build artifacts
clean:
	@flutter clean
	@rm -rf build/
	@rm -rf .dart_tool/
	@rm -rf android/.gradle/
	@rm -rf android/app/build/

# Run code generation
generate:
	@dart run build_runner build --delete-conflicting-outputs

# Run tests with coverage
test-coverage:
	@flutter test --coverage
	@genhtml coverage/lcov.info -o coverage/html

# Check for security issues
security-scan:
	@flutter analyze --no-fatal-infos --no-fatal-warnings
	@echo "Checking for hardcoded secrets..."
	@! grep -r "password\|secret\|api_key" lib/ --include="*.dart" | grep -v "YOUR_" | grep -v "// " || echo "Potential secrets found!"

# Install on connected device
install:
	@flutter install --release

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
	@echo "  make check           - Run all checks"