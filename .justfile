# XCODE_PROJECT_PATH := "./Demo/UltraviolenceDemo.xcodeproj"
XCODE_SCHEME := "UltraviolenceDemo"
CONFIGURATION := "Debug"

default: list

list:
    just --list

build:
    swift build --quiet
    @echo "✅ Build Success"

test:
    swift test --quiet
    @echo "✅ Test Success"

# Run tests with coverage collection
test-coverage:
    swift test --enable-code-coverage
    @echo "✅ Coverage data generated"

# Generate coverage report and show percentage only  
coverage: test-coverage
    @xcrun llvm-cov report \
        .build/debug/*PackageTests.xctest/Contents/MacOS/*PackageTests \
        -instr-profile=.build/debug/codecov/default.profdata \
        -ignore-filename-regex=".build|Tests" \
        | tail -1 | awk '{print "Line Coverage: " $$9}'

# Generate detailed coverage report
coverage-report: test-coverage
    @xcrun llvm-cov report \
        .build/debug/*PackageTests.xctest/Contents/MacOS/*PackageTests \
        -instr-profile=.build/debug/codecov/default.profdata \
        -ignore-filename-regex=".build|Tests"

# Show coverage percentage as a single number (useful for CI)
coverage-percent: test-coverage
    @xcrun llvm-cov report \
        .build/debug/*PackageTests.xctest/Contents/MacOS/*PackageTests \
        -instr-profile=.build/debug/codecov/default.profdata \
        -ignore-filename-regex=".build|Tests" \
        | tail -1 | awk '{print $$9}' | tr -d "%"

push: build test periphery-scan
    jj bookmark move main --to @-; jj git push --branch main

format:
    swiftlint --fix --format --quiet

    fd --extension metal --extension h --exec clang-format -i {}

metal-nm:
    swift build --quiet
    # xcrun metal-nm .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib
    #xcrun metal-objdump  --disassemble-all .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib
    #xcrun metal-source .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib

# periphery-scan-clean:
#     periphery scan --project-root Demo --project UltraviolenceDemo.xcodeproj --schemes UltraviolenceDemo --quiet --write-baseline .periphery.baseline.json --retain-public

periphery-scan:
    #     periphery scan --project-root Demo --project UltraviolenceDemo.xcodeproj --schemes UltraviolenceDemo --quiet --baseline .periphery.baseline.json --write-baseline .periphery.baseline.json --strict --retain-public
    # @echo "✅ periphery-scan Success"
    @echo "‼️ periphery-scan Skipped"


build-docs:
