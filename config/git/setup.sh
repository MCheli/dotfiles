#!/bin/bash
# Git configuration setup

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GIT_TEMPLATE="$DOTFILES_DIR/templates/gitconfig.template"
GITIGNORE_GLOBAL="$DOTFILES_DIR/config/git/gitignore_global"

echo "Setting up Git configuration..."

# Copy global gitignore
if [[ -f "$GITIGNORE_GLOBAL" ]]; then
    cp "$GITIGNORE_GLOBAL" ~/.gitignore_global
    echo "Global gitignore installed to ~/.gitignore_global"
fi

# Setup git configuration if template exists
if [[ -f "$GIT_TEMPLATE" ]]; then
    if [[ ! -f ~/.gitconfig ]]; then
        echo "Installing git configuration template..."
        cp "$GIT_TEMPLATE" ~/.gitconfig
        echo ""
        echo "⚠️  Please edit ~/.gitconfig and update:"
        echo "   - Your name and email in the [user] section"
        echo ""
        echo "Example:"
        echo "   git config --global user.name \"Your Name\""
        echo "   git config --global user.email \"your.email@example.com\""
    else
        echo "Git config already exists. Template available at:"
        echo "   $GIT_TEMPLATE"
    fi
else
    echo "Warning: Git config template not found"
fi