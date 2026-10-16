#!/usr/bin/env bash
# Regenerates Support/AppIcon.icns from scripts/generate-icon.swift.
set -euo pipefail

cd "$(dirname "$0")/.."

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

master="$work_dir/icon_1024.png"
iconset="$work_dir/AppIcon.iconset"
mkdir "$iconset"

swift scripts/generate-icon.swift "$master"

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$master" --out "$iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$master" --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil --convert icns "$iconset" --output Support/AppIcon.icns
echo "Wrote Support/AppIcon.icns"
