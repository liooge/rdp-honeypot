#!/usr/bin/env bash
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
cd "$HERE"
python runner.py --rdp-port "${1:-3101}" --http-port "${2:-8080}"
