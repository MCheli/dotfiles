#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Dotfiles Uninstall ==="
echo "This will remove dotfiles configurations and restore backups where possible."
echo ""

# Confirmation prompt
read -p "Are you sure you want to uninstall dotfiles? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "Starting uninstall process..."

# Remove symlinks and restore backups
restore_file() {
    local file="$1"
    local backup="${file}.backup"

    if [[ -L "$file" ]]; then
        echo "Removing symlink: $file"
        rm "$file"

        # Check for backup and restore
        if [[ -f "$backup" ]]; then
            echo "Restoring backup: $backup -> $file"
            mv "$backup" "$file"
        fi
    elif [[ -f "$file" ]]; then
        echo "Found non-symlink file: $file (leaving as-is)"
    fi
}

# Restore shell configuration
echo ""
echo "Restoring shell configurations..."
restore_file ~/.zshrc
restore_file ~/.p10k.zsh

# Restore other configurations
echo ""
echo "Restoring other configurations..."
restore_file ~/.vimrc
restore_file ~/.gitconfig

# Remove dotfiles-created directories and files
echo ""
echo "Cleaning up dotfiles-specific installations..."

# Remove vim plugins directory
if [[ -d ~/.vim/plugged ]]; then
    echo "Removing vim plugins..."
    rm -rf ~/.vim/plugged
fi

# Remove vim-plug
if [[ -f ~/.vim/autoload/plug.vim ]]; then
    echo "Removing vim-plug..."
    rm -f ~/.vim/autoload/plug.vim
fi

# Remove vim undo directory
if [[ -d ~/.vim/undo ]]; then
    echo "Removing vim undo directory..."
    rm -rf ~/.vim/undo
fi

# SSH config handling
if [[ -f ~/.ssh/config ]]; then
    echo ""
    read -p "Remove SSH configuration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f ~/.ssh/config.backup ]]; then
            echo "Restoring SSH config backup..."
            mv ~/.ssh/config.backup ~/.ssh/config
        else
            echo "Removing SSH config..."
            rm ~/.ssh/config
        fi
    fi
fi

# Remove global gitignore
if [[ -f ~/.gitignore_global ]]; then
    echo "Removing global gitignore..."
    rm ~/.gitignore_global
fi

# Handle manually installed components
echo ""
echo "Note: The following may need manual removal:"
echo ""

# Check for Powerlevel10k
if [[ -d ~/.powerlevel10k ]]; then
    echo "- Powerlevel10k theme: ~/.powerlevel10k"
    read -p "  Remove Powerlevel10k? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.powerlevel10k
        echo "  ✓ Powerlevel10k removed"
    fi
fi

# Check for zsh plugins
for plugin in ~/.zsh-autosuggestions ~/.zsh-syntax-highlighting; do
    if [[ -d "$plugin" ]]; then
        echo "- Plugin: $plugin"
        read -p "  Remove $(basename "$plugin")? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$plugin"
            echo "  ✓ $(basename "$plugin") removed"
        fi
    fi
done

# macOS specific cleanup
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "macOS-specific cleanup:"
    echo "- Homebrew packages (powerlevel10k, zsh-autosuggestions, etc.) - use 'brew uninstall'"
    echo "- Terminal.app profile settings - reset manually in Terminal preferences"
    echo "- MesloLGS Nerd Font - remove via Font Book or 'brew uninstall --cask font-meslo-lg-nerd-font'"
fi

# Shell reset
echo ""
read -p "Reset shell to system default? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v bash &>/dev/null; then
        echo "Setting shell back to bash..."
        chsh -s "$(which bash)"
        echo "✓ Shell changed to bash"
    else
        echo "! Bash not found, keeping current shell"
    fi
fi

# Optional: Remove dotfiles directory
echo ""
read -p "Remove dotfiles directory ($DOTFILES_DIR)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing dotfiles directory..."
    cd ~
    rm -rf "$DOTFILES_DIR"
    echo "✓ Dotfiles directory removed"
fi

echo ""
echo "=========================================="
echo "         Uninstall Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "✓ Dotfiles symlinks removed"
echo "✓ Backup files restored (where available)"
echo "✓ Plugin directories cleaned up"
echo ""
echo "You may want to:"
echo "1. Restart your terminal"
echo "2. Remove any remaining Homebrew packages manually"
echo "3. Reset terminal theme/font preferences"
echo ""
echo "Thank you for using these dotfiles!"