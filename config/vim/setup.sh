#!/bin/bash
# Vim configuration setup

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VIM_CONFIG="$DOTFILES_DIR/config/vim/vimrc"

echo "Setting up Vim configuration..."

# Backup existing vimrc
if [[ -f ~/.vimrc && ! -L ~/.vimrc ]]; then
    echo "Backing up existing ~/.vimrc to ~/.vimrc.backup"
    mv ~/.vimrc ~/.vimrc.backup
fi

# Create symlink to dotfiles vimrc
if [[ -f "$VIM_CONFIG" ]]; then
    ln -sf "$VIM_CONFIG" ~/.vimrc
    echo "✓ Vim configuration linked to ~/.vimrc"
else
    echo "! Vim configuration not found: $VIM_CONFIG"
    exit 1
fi

# Install vim-plug if not present and install plugins
if command -v vim &>/dev/null; then
    echo "Installing vim plugins..."
    vim +PlugInstall +qall
    echo "✓ Vim plugins installed"
else
    echo "! Vim not found - skipping plugin installation"
fi

echo "Vim setup complete!"
echo ""
echo "Key mappings (leader key is space):"
echo "  <space>f  - Fuzzy file finder"
echo "  <space>t  - Toggle file tree"
echo "  <space>h  - Clear search highlighting"
echo "  <space>w  - Save file"
echo "  <space>q  - Quit"
echo ""
echo "For local customizations, create ~/.vimrc.local"