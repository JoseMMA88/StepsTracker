#!/bin/sh
set -eu

# Xcode Cloud runs this script in a disposable checkout. For an archive it makes
# CFBundleVersion match the unique Xcode Cloud build number without modifying the
# version stored in source control.
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

cd "${CI_WORKSPACE_PATH:?Xcode Cloud must provide CI_WORKSPACE_PATH}"
xcrun agvtool new-version -all "${CI_BUILD_NUMBER}"
