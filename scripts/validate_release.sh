#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_PATH="${ROOT_DIR}/StepsTracker.xcodeproj"
readonly SCHEME="StepsTracker"
readonly INFO_PLIST="${ROOT_DIR}/StepsTracker/Info.plist"

destination=""
skip_tests=false

usage() {
    cat <<'EOF'
Usage: scripts/validate_release.sh [--destination <xcodebuild destination>] [--skip-tests]

Validates the project configuration and, unless skipped, runs the unit tests on
an available iPhone simulator. Set --destination when a specific simulator is
required, for example: 'platform=iOS Simulator,name=iPhone 16,OS=latest'.
EOF
}

fail() {
    echo "error: $*" >&2
    exit 1
}

available_iphone_destination() {
    local simulator_id
    simulator_id="$(xcrun simctl list devices available -j | python3 -c '
import json
import sys

devices_by_runtime = json.load(sys.stdin).get("devices", {})
for runtime in sorted(devices_by_runtime, reverse=True):
    if not runtime.startswith("com.apple.CoreSimulator.SimRuntime.iOS-"):
        continue
    for device in devices_by_runtime[runtime]:
        if device.get("isAvailable") and device.get("name", "").startswith("iPhone"):
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit(1)
' 2>/dev/null || true)"

    [[ -n "${simulator_id}" ]] || return 1
    printf 'platform=iOS Simulator,id=%s\n' "${simulator_id}"
}

while (($#)); do
    case "$1" in
        --destination)
            (($# >= 2)) || fail "--destination requires a value."
            destination="$2"
            shift 2
            ;;
        --skip-tests)
            skip_tests=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "Unknown option: $1"
            ;;
    esac
done

command -v xcodebuild >/dev/null || fail "Xcode command-line tools are required."
command -v plutil >/dev/null || fail "plutil is required."
[[ -d "${PROJECT_PATH}" ]] || fail "Project not found at ${PROJECT_PATH}."

git -C "${ROOT_DIR}" diff --check
plutil -lint "${INFO_PLIST}"
for privacy_key in NSHealthShareUsageDescription NSHealthUpdateUsageDescription; do
    privacy_value="$(plutil -extract "${privacy_key}" raw "${INFO_PLIST}" 2>/dev/null || true)"
    [[ -n "${privacy_value}" ]] || fail "${privacy_key} must contain a user-facing purpose string."
done
xcodebuild -list -project "${PROJECT_PATH}" -json >/dev/null
xcodebuild -showBuildSettings \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination 'generic/platform=iOS' >/dev/null

if [[ "${skip_tests}" == true ]]; then
    echo "Release configuration validated; tests skipped."
    exit 0
fi

if [[ -z "${destination}" ]]; then
    destination="$(available_iphone_destination || true)"
fi

[[ -n "${destination}" ]] || fail "No available iPhone simulator found. Pass --destination explicitly."

xcodebuild test \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -destination "${destination}"

echo "Release configuration and tests passed."
