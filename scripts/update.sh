#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Updating Dotfiles ==="
echo "Dotfiles directory: $DOTFILES_DIR"

# Update dotfiles repository
echo "Updating dotfiles repository..."
if git -C "$DOTFILES_DIR" status &>/dev/null; then
    git -C "$DOTFILES_DIR" pull
    echo "✓ Dotfiles updated"
else
    echo "! Not a git repository - skipping git pull"
fi

# Detect OS
OS="$(uname -s)"

# Update system dependencies
echo ""
echo "Updating system packages..."
if [[ "$OS" == "Darwin" ]]; then
    # macOS - Update Homebrew
    if command -v brew &>/dev/null; then
        echo "Updating Homebrew packages..."
        brew update
        brew upgrade
        brew upgrade --cask
        brew cleanup
        echo "✓ Homebrew packages updated"
    else
        echo "! Homebrew not installed"
    fi

elif [[ "$OS" == "Linux" ]]; then
    # Linux - Update packages
    if command -v apt-get &>/dev/null; then
        echo "Updating apt packages..."
        sudo apt-get update
        sudo apt-get upgrade -y
        sudo apt-get autoremove -y
        echo "✓ APT packages updated"
    elif command -v dnf &>/dev/null; then
        echo "Updating dnf packages..."
        sudo dnf upgrade -y
        echo "✓ DNF packages updated"
    elif command -v yum &>/dev/null; then
        echo "Updating yum packages..."
        sudo yum update -y
        echo "✓ YUM packages updated"
    elif command -v pacman &>/dev/null; then
        echo "Updating pacman packages..."
        sudo pacman -Syu --noconfirm
        echo "✓ Pacman packages updated"
    fi
fi

# Update Powerlevel10k
echo ""
echo "Updating Powerlevel10k..."
if [[ -d "$HOME/.powerlevel10k" ]]; then
    git -C "$HOME/.powerlevel10k" pull --depth=1
    echo "✓ Powerlevel10k updated"
elif [[ -f "/opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
    # Powerlevel10k is managed by Homebrew, already updated above
    echo "✓ Powerlevel10k updated via Homebrew"
else
    echo "! Powerlevel10k not found"
fi

# Update zsh plugins
echo ""
echo "Updating zsh plugins..."
for plugin_dir in "$HOME/.zsh-autosuggestions" "$HOME/.zsh-syntax-highlighting"; do
    if [[ -d "$plugin_dir" ]]; then
        echo "Updating $(basename "$plugin_dir")..."
        git -C "$plugin_dir" pull --depth=1 2>/dev/null || echo "! Failed to update $(basename "$plugin_dir")"
    fi
done

# Update vim plugins (if using vim-plug)
if [[ -f ~/.vim/autoload/plug.vim ]] && command -v vim &>/dev/null; then
    echo ""
    echo "Updating vim plugins..."
    vim +PlugUpdate +qall
    echo "✓ Vim plugins updated"
fi

# Update neovim plugins (if using packer.nvim)
if [[ -d ~/.local/share/nvim/site/pack/packer ]] && command -v nvim &>/dev/null; then
    echo ""
    echo "Updating neovim plugins..."
    nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
    echo "✓ Neovim plugins updated"
fi

# Update Node.js global packages
if command -v npm &>/dev/null; then
    echo ""
    echo "Updating npm global packages..."
    npm update -g
    echo "✓ Global npm packages updated"
fi

# Update Python packages
if command -v pip3 &>/dev/null; then
    echo ""
    echo "Updating pip packages..."
    pip3 list --outdated --format=json | jq -r '.[].name' | xargs -n1 pip3 install -U 2>/dev/null || echo "! Some pip packages failed to update"
    echo "✓ Pip packages updated"
fi

# Reload shell configuration
echo ""
echo "Reloading shell configuration..."
if [[ -n "$ZSH_VERSION" ]]; then
    source ~/.zshrc
    echo "✓ Zsh configuration reloaded"
elif [[ -n "$BASH_VERSION" ]]; then
    source ~/.bashrc 2>/dev/null || source ~/.bash_profile 2>/dev/null || true
    echo "✓ Bash configuration reloaded"
fi

echo ""
echo "=========================================="
echo "         Update Complete!"
echo "=========================================="
echo ""
echo "Summary of updates:"
echo "✓ Dotfiles repository"
echo "✓ System packages"
echo "✓ Shell theme and plugins"
echo "✓ Development tools (if installed)"
echo ""
echo "Note: Restart your terminal to ensure all changes take effect."