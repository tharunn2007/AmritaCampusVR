#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
engine="${GODOT_BIN:-/mnt/1A66ECB966EC9733/Godot_v4.7.2-stable_linux.x86_64}"
exec "$engine" --editor --path "$project_dir"
