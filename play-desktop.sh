#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
engine="${GODOT_BIN:-/mnt/1A66ECB966EC9733/Godot_v4.7.2-stable_linux.x86_64}"
"$engine" --headless --editor --import --path "$project_dir" --xr-mode off
exec "$engine" --path "$project_dir" --xr-mode off
