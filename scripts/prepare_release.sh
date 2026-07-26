#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

version=""
build_number=""

usage() {
    cat <<'EOF'
Usage: scripts/prepare_release.sh --version <major.minor[.patch]> --build <positive integer>

Updates the marketing and build versions in the Xcode project. It deliberately
does not create a commit, tag, archive, or upload: review and commit this small
change before a reproducible release is created from that commit.
EOF
}

fail() {
    echo "error: $*" >&2
    exit 1
}

release_worktree_status() {
    git -C "${ROOT_DIR}" status --porcelain --untracked-files=all |
        awk 'substr($0, 4) !~ /(^|\/)xcuserdata\// && substr($0, 4) !~ /\.xcuserstate$/'
}

while (($#)); do
    case "$1" in
        --version)
            (($# >= 2)) || fail "--version requires a value."
            version="$2"
            shift 2
            ;;
        --build)
            (($# >= 2)) || fail "--build requires a value."
            build_number="$2"
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

[[ "${version}" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || fail "Version must use major.minor or major.minor.patch."
[[ "${build_number}" =~ ^[1-9][0-9]*$ ]] || fail "Build must be a positive integer."
[[ -z "$(release_worktree_status)" ]] || fail "Commit, stash, or discard existing changes before preparing a release."

command -v xcrun >/dev/null || fail "Xcode command-line tools are required."

cd "${ROOT_DIR}"
xcrun agvtool new-marketing-version "${version}"
xcrun agvtool new-version -all "${build_number}"

echo "Prepared version ${version} (${build_number})."
echo "Next: validate, commit, tag the commit, then use the TestFlight workflow."
