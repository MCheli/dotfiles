#!/bin/bash
# One-liner bootstrap for remote servers
# Usage: curl -fsSL https://raw.githubusercontent.com/MCheli/dotfiles/main/scripts/bootstrap.sh | bash
#    or: wget -qO- https://raw.githubusercontent.com/MCheli/dotfiles/main/scripts/bootstrap.sh | bash

set -e

REPO_URL="${DOTFILES_REPO:-https://github.com/MCheli/dotfiles.git}"
DOTFILES_DIR="$HOME/dotfiles"

echo "=== Dotfiles Bootstrap ==="

# Install git if not present
if ! command -v git &>/dev/null; then
    echo "Installing git..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y git
    elif command -v yum &>/dev/null; then
        sudo yum install -y git
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y git
    fi
fi

# Clone or update dotfiles
if [[ -d "$DOTFILES_DIR" ]]; then
    echo "Updating existing dotfiles..."
    git -C "$DOTFILES_DIR" pull
else
    echo "Cloning dotfiles..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# Run setup
exec "$DOTFILES_DIR/scripts/setup.sh"
