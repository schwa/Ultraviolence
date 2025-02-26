XCODE_PROJECT_PATH := "./Demo/UltraviolenceDemo.xcodeproj"
XCODE_SCHEME := "UltraviolenceDemo"

build:
    swift build --quiet
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=macOS" -quiet -skipPackagePluginValidation build ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=iOS" -quiet -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "platform=iOS Simulator,name=iPhone 16 Plus" -quiet -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO

test: build
    swift test --quiet

push: test
    jj bookmark move main --to @-; jj git push --branch main
