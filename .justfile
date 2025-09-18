# XCODE_PROJECT_PATH := "./Demo/UltraviolenceDemo.xcodeproj"
XCODE_SCHEME := "UltraviolenceDemo"
CONFIGURATION := "Debug"

default: list

list:
    just --list

build:
    swift build --quiet

test:
    swift test --quiet

coverage-percent:
    swift test --enable-code-coverage --quiet
    #.build/arm64-apple-macosx/debug/codecov/Ultraviolence.json
    xcrun llvm-cov report \
        .build/arm64-apple-macosx/debug/UltraviolencePackageTests.xctest/Contents/MacOS/UltraviolencePackageTests \
        -instr-profile=.build/arm64-apple-macosx/debug/codecov/default.profdata \
        -ignore-filename-regex=".build|Tests|UltraviolenceExamples|UltraviolenceGaussianSplats|UltraviolenceSupport|UltraviolenceUI" \
        | tail -1 | grep -oE '[0-9]+\.[0-9]+%' | head -n1

format:
    swiftlint --fix --format --quiet
    fd --extension metal --extension h --exec clang-format -i {}

open-container:
    open "$HOME/Library/Containers/io.schwa.UltraviolenceExamples/Data"
