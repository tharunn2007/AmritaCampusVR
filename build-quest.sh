#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
engine="${GODOT_BIN:-/mnt/1A66ECB966EC9733/Godot_v4.7.2-stable_linux.x86_64}"
# Uses a project-local editor configuration, preserving your global editor settings.
export XDG_CONFIG_HOME="$project_dir/builds/editor-config"
exec "$engine" --headless --path "$project_dir" --export-debug 'Meta Quest' builds/amrita-campus-quest.apk
