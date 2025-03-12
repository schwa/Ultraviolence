XCODE_PROJECT_PATH := "./Demo/UltraviolenceDemo.xcodeproj"
XCODE_SCHEME := "UltraviolenceDemo"

default: list

list:
    just --list


build:
    swift build --quiet
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=macOS" -quiet -skipPackagePluginValidation build ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=iOS" -quiet -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "platform=iOS Simulator,name=iPhone 16 Plus" -quiet -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO
    @echo "✅ Build Success"

test:
    swift test --quiet
    @echo "✅ Test Success"

push: build test periphery-scan
    jj bookmark move main --to @-; jj git push --branch main

format:
    swiftlint --fix --format --quiet

    fd --extension metal --extension h --exec clang-format -i {}

metal-nm:
    swift build --quiet
    xcrun metal-nm .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib
    #xcrun metal-objdump  --disassemble-all .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib
    #xcrun metal-source .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib

periphery-scan:
    periphery scan --project-root Demo --project UltraviolenceDemo.xcodeproj --schemes UltraviolenceDemo --quiet --baseline .periphery.baseline.json --write-baseline .periphery.baseline.json --strict
    # --retain-public
