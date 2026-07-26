#!/bin/sh
set -eu

# Xcode Cloud assigns CI_BUILD_NUMBER to distributed archives itself. This hook
# only validates the value; it must not mutate the project before archiving.
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

echo "Xcode Cloud archive build number: ${CI_BUILD_NUMBER}"
