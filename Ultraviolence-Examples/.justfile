XCODE_PROJECT := "Ultraviolence-Examples.xcodeproj"
XCODE_SCHEME := "Ultraviolence-Examples"
CONFIGURATION := "Debug"

default: list

list:
    just --list

build-macOS:
    xcodebuild \
        -scheme "{{ XCODE_SCHEME }}" \
        -configuration "{{ CONFIGURATION }}" \
        -destination 'platform=macOS,name=Any Mac' \
        build | xcpretty
    @echo "✅ macOS Build Success"

build-iOS:
    xcodebuild \
        -scheme "{{ XCODE_SCHEME }}" \
        -configuration "{{ CONFIGURATION }}" \
        -destination 'platform=iOS,name=Any iOS Device' \
        build | xcpretty
    xcodebuild \
        -scheme "{{ XCODE_SCHEME }}" \
        -configuration "{{ CONFIGURATION }}" \
        -destination 'platform=iOS Simulator,name=Any iOS Simulator Device' \
        build | xcpretty
    @echo "✅ iOS Build Success"

build: build-macOS build-iOS
    @echo "✅ Build Success"

test:
    swift test --quiet --package-path Packages/UltraviolenceExamples
    @echo "✅ Test Success"

push: build test
    jj bookmark move main --to @-; jj git push --branch main

format:
    swiftlint --fix --format --quiet
    fd --extension metal --extension h --exec clang-format -i {}
