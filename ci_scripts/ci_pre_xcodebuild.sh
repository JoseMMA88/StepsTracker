#!/bin/sh
set -eu

# Xcode Cloud assigns CI_BUILD_NUMBER to distributed archives itself.
if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
    exit 0
fi

case "${CI_BUILD_NUMBER:-}" in
    '' | *[!0-9]*)
        echo "error: CI_BUILD_NUMBER must be a positive integer for an archive." >&2
        exit 1
        ;;
esac

if [ "${CI_BUILD_NUMBER}" -eq 0 ]; then
    echo "error: CI_BUILD_NUMBER must be greater than zero." >&2
    exit 1
fi

if ! ios_sdk_version="$(xcrun --sdk iphoneos --show-sdk-version)" ||
    ! [ "${ios_sdk_version%%.*}" -ge 27 ] 2>/dev/null; then
    echo "error: Xcode Cloud archives require iOS SDK 27 or later (found ${ios_sdk_version:-none})." >&2
    exit 1
fi

echo "Xcode Cloud archive iOS SDK: ${ios_sdk_version}"
echo "Xcode Cloud archive build number: ${CI_BUILD_NUMBER}"
