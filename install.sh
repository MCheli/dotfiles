#!/bin/bash
# Convenience script that calls the main setup
# This provides a more intuitive entry point for local installations

exec "$(dirname "${BASH_SOURCE[0]}")/scripts/setup.sh" "$@"