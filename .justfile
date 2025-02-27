XCODE_PROJECT_PATH := "./Demo/UltraviolenceDemo.xcodeproj"
XCODE_SCHEME := "UltraviolenceDemo"

build:
    swift build --quiet
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=macOS" -quiet -skipPackagePluginValidation build ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=iOS" -quiet -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "platform=iOS Simulator,name=iPhone 16 Plus" -quiet -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO

test:
    swift test --quiet

push: build test
    jj bookmark move main --to @-; jj git push --branch main

format:
    swiftlint --fix --format --quiet

metal-nm:
    swift build --quiet
    xcrun metal-nm .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib
    #xcrun metal-objdump  --disassemble-all .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib
    #xcrun metal-source .build/arm64-apple-macosx/debug/Ultraviolence_UltraviolenceExamples.bundle/debug.metallib
