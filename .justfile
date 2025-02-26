XCODE_PROJECT_PATH := "./Demo/UltraviolenceDemo.xcodeproj"
XCODE_SCHEME := "UltraviolenceDemo"

build:
    swift build -v
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=macOS" -skipPackagePluginValidation build ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=iOS" -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "platform=iOS Simulator,name=iPhone 16 Plus" -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO

test: build
    swift test -v

push: test
    jj bookmark move main --to @-; jj git push --branch main
