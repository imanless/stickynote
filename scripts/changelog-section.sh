#!/usr/bin/env bash
# Prints the CHANGELOG.md entry for a version, for use as release notes.
# Fails if there is no entry, so a release can't go out undocumented.
# Usage: scripts/changelog-section.sh 1.2.0
set -euo pipefail

cd "$(dirname "$0")/.."

version="${1:?usage: $0 <version>}"

notes="$(awk -v heading="## [$version]" '
    index($0, heading) == 1 { found = 1; next }
    found && /^## \[/ { exit }
    found && /^\[[^]]+\]: / { exit }
    found { print }
' CHANGELOG.md)"

if [[ -z "${notes//[[:space:]]/}" ]]; then
    echo "error: CHANGELOG.md has no entry for $version" >&2
    exit 1
fi

printf '%s\n' "$notes"
