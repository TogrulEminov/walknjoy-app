#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
template=config/APIConfig.swift.example
target=${1:-walknjoy/walknjoy/Core/Config/APIConfig.swift}
if [ ! -f "$template" ]; then
  echo "Missing tracked configuration template: $template" >&2
  exit 1
fi
mkdir -p "$(dirname "$target")"
if [ ! -f "$target" ]; then
  cp "$template" "$target"
fi
