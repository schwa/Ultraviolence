XCODE_PROJECT_PATH := "./Demo/UltraviolenceDemo.xcodeproj"
XCODE_SCHEME := "UltraviolenceDemo"
CONFIGURATION := "Debug"

default: list

list:
    just --list


build:
    swift build --quiet
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=macOS" -quiet -skipPackagePluginValidation build ARCHS=arm64 ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO -configuration "{{ CONFIGURATION }}"
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "generic/platform=iOS" -quiet -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO -configuration "{{ CONFIGURATION }}"
    xcodebuild -project "{{XCODE_PROJECT_PATH}}" -scheme "{{XCODE_SCHEME}}" -destination "platform=iOS Simulator,name=iPhone 16 Plus" -quiet -skipPackagePluginValidation build CODE_SIGNING_ALLOWED=NO -configuration "{{ CONFIGURATION }}"
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

periphery-scan-clean:
    periphery scan --project-root Demo --project UltraviolenceDemo.xcodeproj --schemes UltraviolenceDemo --quiet --write-baseline .periphery.baseline.json --retain-public

periphery-scan:
    periphery scan --project-root Demo --project UltraviolenceDemo.xcodeproj --schemes UltraviolenceDemo --quiet --baseline .periphery.baseline.json --write-baseline .periphery.baseline.json --strict --retain-public
    @echo "✅ periphery-scan Success"

create-todo-tickets:
    #!/usr/bin/env fish
    set RESULTS (rg "TODO: (?!\s*#\d)" -n --pcre2 --json --type-add 'code:*.{,swift,metal,h}' | jq -c '. | select(.type=="match")')

    for RESULT in $RESULTS
        # Extract file path, line number, and the TODO text
        set FILE_PATH (echo $RESULT | jq -r '.data.path.text')
        set LINE_NUMBER (echo $RESULT | jq -r '.data.line_number')
        set TODO_TEXT (echo $RESULT | jq -r '.data.lines.text' | string trim)

        echo "Processing TODO in $FILE_PATH at line $LINE_NUMBER: $TODO_TEXT"

        # Create a GitHub issue and capture the issue URL
        set ISSUE_URL (gh issue create --title "TODO: $TODO_TEXT" --body "Found in $FILE_PATH at line $LINE_NUMBER" | tee /dev/tty)

        # Extract the issue number from the URL
        set ISSUE_NUMBER (echo $ISSUE_URL | string replace -r '.*/issues/(\d+)' '$1')

        echo "Created issue #$ISSUE_NUMBER for TODO"

        # Modify the file by appending the issue number to the TODO
        set TEMP_FILE (mktemp)

        awk -v LINE_NUM=$LINE_NUMBER -v ISSUE_NUM=$ISSUE_NUMBER '
        NR==LINE_NUM {
            sub(/TODO: /, "TODO: #" ISSUE_NUM " ", $0);
        }
        { print }
        ' "$FILE_PATH" > "$TEMP_FILE" && mv "$TEMP_FILE" "$FILE_PATH"

        echo "Updated TODO in $FILE_PATH to reference issue #$ISSUE_NUMBER"
    end
