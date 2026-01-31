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

# Install vim-plug and plugins
if command -v vim &>/dev/null; then
    echo "Installing vim plugins..."

    # Ensure vim-plug is installed first
    if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
        echo "Installing vim-plug..."
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi

    # Check if we're in a non-interactive environment
    if [[ ! -t 0 ]] || [[ ! -t 1 ]] || [[ -n "$SSH_CLIENT" ]]; then
        # Non-interactive mode - skip plugin installation
        echo "Non-interactive mode detected - vim-plug installed"
        echo "Plugins will be installed automatically on first vim use"
        echo "Or run manually: vim +PlugInstall +qall"
    else
        # Interactive mode - install plugins
        vim +PlugInstall +qall 2>/dev/null
    fi

    echo "✓ Vim plugins setup complete"
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