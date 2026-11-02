#!/bin/sh
set -eu

# Keep the existing CI/local entrypoint; all three files share one classifier.
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$script_dir/.."
exec python3 -B "$script_dir/generate_ros.py"
