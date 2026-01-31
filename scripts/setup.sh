#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Dotfiles Setup ==="
echo "Dotfiles directory: $DOTFILES_DIR"

# Detect OS
OS="$(uname -s)"
echo "Detected OS: $OS"

# Install Homebrew (macOS) or use apt (Linux)
install_dependencies() {
    if [[ "$OS" == "Darwin" ]]; then
        # macOS
        if ! command -v brew &>/dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        echo "Installing packages via Homebrew..."
        brew install powerlevel10k zsh-autosuggestions zsh-syntax-highlighting

        # Install Nerd Font (only on local machine, not SSH)
        if [[ -z "$SSH_CLIENT" ]]; then
            brew install --cask font-meslo-lg-nerd-font
        fi

    elif [[ "$OS" == "Linux" ]]; then
        # Linux
        echo "Installing zsh..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y zsh git curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y zsh git curl
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm zsh git curl
        fi

        # Install Powerlevel10k
        if [[ ! -d "${HOME}/.powerlevel10k" ]]; then
            echo "Installing Powerlevel10k..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
        fi

        # Install zsh plugins
        if [[ ! -d "${HOME}/.zsh-autosuggestions" ]]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh-autosuggestions
        fi
        if [[ ! -d "${HOME}/.zsh-syntax-highlighting" ]]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh-syntax-highlighting
        fi
    fi
}

# Create symlinks for dotfiles
create_symlinks() {
    echo "Creating symlinks..."

    # Backup existing files
    for file in ~/.zshrc ~/.p10k.zsh; do
        if [[ -f "$file" && ! -L "$file" ]]; then
            echo "Backing up $file to ${file}.backup"
            mv "$file" "${file}.backup"
        fi
    done

    # Create symlinks
    ln -sf "$DOTFILES_DIR/zsh/zshrc" ~/.zshrc

    if [[ -f "$DOTFILES_DIR/zsh/p10k.zsh" ]]; then
        ln -sf "$DOTFILES_DIR/zsh/p10k.zsh" ~/.p10k.zsh
    fi
}

# Set zsh as default shell
set_default_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        echo "Setting zsh as default shell..."
        if grep -q "$(which zsh)" /etc/shells; then
            chsh -s "$(which zsh)"
        else
            echo "$(which zsh)" | sudo tee -a /etc/shells
            chsh -s "$(which zsh)"
        fi
    fi
}

# Main
main() {
    install_dependencies
    create_symlinks
    set_default_shell

    echo ""
    echo "=== Setup Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: exec zsh"
    echo "2. Run 'p10k configure' to customize your prompt"
    echo ""
    if [[ "$OS" == "Darwin" && -z "$SSH_CLIENT" ]]; then
        echo "3. Set your terminal font to 'MesloLGS Nerd Font'"
        echo "4. Import Dracula.terminal theme: open $DOTFILES_DIR/terminal/Dracula.terminal"
    fi
}

main "$@"
