#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly PROJECT_PATH="${ROOT_DIR}/StepsTracker.xcodeproj"
readonly SCHEME="StepsTracker"
readonly EXPORT_OPTIONS="${ROOT_DIR}/release/ExportOptions.plist"

destination=""
skip_tests=false
dry_run=false
output_dir="${ROOT_DIR}/build/release"

usage() {
    cat <<'EOF'
Usage: scripts/release_to_testflight.sh [options]

Archives the committed source, exports an App Store IPA using automatic signing,
and uploads it to TestFlight with an App Store Connect API key.

Options:
  --destination <destination>  Simulator destination to use for tests.
  --skip-tests                 Do not run unit tests before archiving.
  --dry-run                    Validate prerequisites without archiving or uploading.
  --output-dir <path>          Directory for the archive and IPA (default: build/release).

Required environment variables:
  ASC_KEY_ID                   App Store Connect API key ID.
  ASC_ISSUER_ID                App Store Connect API issuer ID.

Optional environment variable:
  ASC_API_KEY_DIRECTORY        Directory containing AuthKey_<ASC_KEY_ID>.p8.
                              Defaults to ~/.appstoreconnect/private_keys.
EOF
}

fail() {
    echo "error: $*" >&2
    exit 1
}

build_setting() {
    local key="$1"
    xcodebuild -showBuildSettings \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME}" \
        -configuration Release \
        -destination 'generic/platform=iOS' 2>/dev/null |
        awk -F ' = ' -v key="${key}" '$1 ~ "^[[:space:]]*" key "[[:space:]]*$" { print $2; exit }'
}

release_worktree_status() {
    git -C "${ROOT_DIR}" status --porcelain --untracked-files=all |
        awk 'substr($0, 4) !~ /(^|\/)xcuserdata\// && substr($0, 4) !~ /\.xcuserstate$/'
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
        --dry-run)
            dry_run=true
            shift
            ;;
        --output-dir)
            (($# >= 2)) || fail "--output-dir requires a path."
            output_dir="$2"
            shift 2
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

if [[ "${dry_run}" == false ]]; then
    [[ -z "$(release_worktree_status)" ]] || fail "A release must start from a clean, committed worktree."
fi
[[ -f "${EXPORT_OPTIONS}" ]] || fail "Export options not found at ${EXPORT_OPTIONS}."

if [[ "${skip_tests}" == true ]]; then
    "${SCRIPT_DIR}/validate_release.sh" --skip-tests
else
    validate_args=()
    if [[ -n "${destination}" ]]; then
        validate_args=(--destination "${destination}")
    fi
    "${SCRIPT_DIR}/validate_release.sh" "${validate_args[@]}"
fi

release_version="$(build_setting MARKETING_VERSION)"
release_build="$(build_setting CURRENT_PROJECT_VERSION)"
[[ "${release_version}" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || fail "Invalid MARKETING_VERSION: ${release_version:-<empty>}"
[[ "${release_build}" =~ ^[1-9][0-9]*$ ]] || fail "Invalid CURRENT_PROJECT_VERSION: ${release_build:-<empty>}"

echo "Preparing StepsTracker ${release_version} (${release_build})."

if [[ "${dry_run}" == true ]]; then
    echo "Dry run complete. No archive or upload was created."
    exit 0
fi

: "${ASC_KEY_ID:?Set ASC_KEY_ID before uploading.}"
: "${ASC_ISSUER_ID:?Set ASC_ISSUER_ID before uploading.}"

api_key_directory="${ASC_API_KEY_DIRECTORY:-${HOME}/.appstoreconnect/private_keys}"
api_key_path="${api_key_directory}/AuthKey_${ASC_KEY_ID}.p8"
[[ -r "${api_key_path}" ]] || fail "App Store Connect key not readable at ${api_key_path}."

archive_path="${output_dir}/StepsTracker-${release_version}-${release_build}.xcarchive"
export_path="${output_dir}/StepsTracker-${release_version}-${release_build}"
ipa_path="${export_path}/StepsTracker.ipa"

[[ ! -e "${archive_path}" ]] || fail "Archive already exists: ${archive_path}"
[[ ! -e "${export_path}" ]] || fail "Export directory already exists: ${export_path}"

mkdir -p "${output_dir}"

xcodebuild archive \
    -project "${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "${archive_path}" \
    -allowProvisioningUpdates

xcodebuild -exportArchive \
    -archivePath "${archive_path}" \
    -exportOptionsPlist "${EXPORT_OPTIONS}" \
    -exportPath "${export_path}" \
    -allowProvisioningUpdates

[[ -f "${ipa_path}" ]] || fail "IPA export failed: ${ipa_path} was not created."

API_PRIVATE_KEYS_DIR="${api_key_directory}" xcrun altool --validate-app \
    --file "${ipa_path}" \
    --type ios \
    --api-key "${ASC_KEY_ID}" \
    --api-issuer "${ASC_ISSUER_ID}"

API_PRIVATE_KEYS_DIR="${api_key_directory}" xcrun altool --upload-app \
    --file "${ipa_path}" \
    --type ios \
    --api-key "${ASC_KEY_ID}" \
    --api-issuer "${ASC_ISSUER_ID}"

echo "Uploaded ${release_version} (${release_build}) to App Store Connect."
echo "Wait for Apple processing before selecting it in TestFlight or App Review."
