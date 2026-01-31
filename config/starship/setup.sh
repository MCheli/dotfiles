#!/bin/bash
# Starship prompt setup script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Starship Prompt Setup ==="

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Install Starship based on OS
install_starship() {
    if command -v starship &>/dev/null; then
        echo "Starship is already installed"
        starship --version
        return 0
    fi

    echo "Installing Starship prompt..."

    case "$OS" in
        Darwin)
            # macOS - Use Homebrew if available, otherwise direct install
            if command -v brew &>/dev/null; then
                brew install starship
            else
                echo "Installing Starship via curl..."
                curl -sS https://starship.rs/install.sh | sh
            fi
            ;;

        Linux)
            # Linux - Use package manager if available, otherwise direct install
            if command -v apt-get &>/dev/null && [ -f /etc/debian_version ]; then
                # Debian/Ubuntu - unfortunately no official package, use curl
                echo "Installing Starship via curl (Debian/Ubuntu)..."
                curl -sS https://starship.rs/install.sh | sh
            elif command -v dnf &>/dev/null; then
                # Fedora
                sudo dnf install starship
            elif command -v pacman &>/dev/null; then
                # Arch Linux
                sudo pacman -S --noconfirm starship
            else
                # Fallback to curl install
                echo "Installing Starship via curl..."
                curl -sS https://starship.rs/install.sh | sh
            fi
            ;;

        *)
            echo "Unsupported operating system: $OS"
            echo "Please install Starship manually: https://starship.rs/"
            return 1
            ;;
    esac

    # Verify installation
    if command -v starship &>/dev/null; then
        echo "✓ Starship installed successfully"
        starship --version
    else
        echo "⚠ Starship installation may have failed"
        echo "Please check the installation and try again"
        return 1
    fi
}

# Setup Starship configuration
setup_starship_config() {
    echo "Setting up Starship configuration..."

    # Create config directory
    mkdir -p ~/.config

    # Backup existing starship config
    if [[ -f ~/.config/starship.toml && ! -L ~/.config/starship.toml ]]; then
        echo "Backing up existing starship.toml"
        mv ~/.config/starship.toml ~/.config/starship.toml.backup.$(date +%Y%m%d_%H%M%S)
    fi

    # Check if interactive mode
    if [[ -t 0 ]] && [[ -z "$SSH_CLIENT" || -t 1 ]]; then
        # Interactive mode - let user choose style
        echo ""
        echo "Available Starship styles:"
        echo "  1) P10K Match (default) - Exact match to your Powerlevel10k theme"
        echo "  2) Lean - Minimalist single-line like P10K lean"
        echo "  3) Pure - Clean two-line like P10K pure"
        echo "  4) Powerline - Classic powerline with arrows"
        echo "  5) Original - Original colorful segments"
        echo ""

        while true; do
            read -p "Choose style [1-5] (default: 1): " choice
            case ${choice:-1} in
                1)
                    config_file="starship.toml"
                    echo "Using P10K-matched style"
                    break
                    ;;
                2)
                    config_file="lean.toml"
                    echo "Using lean style"
                    break
                    ;;
                3)
                    config_file="pure.toml"
                    echo "Using pure style"
                    break
                    ;;
                4)
                    config_file="powerline.toml"
                    echo "Using powerline style"
                    break
                    ;;
                5)
                    config_file="starship-original.toml"
                    echo "Using original colorful style"
                    break
                    ;;
                *)
                    echo "Please enter 1, 2, 3, or 4"
                    ;;
            esac
        done
    else
        # Non-interactive mode - use default
        config_file="starship.toml"
        echo "Using default colorful style (non-interactive mode)"
    fi

    # Create symlink to chosen starship config
    echo "Linking Starship configuration..."
    ln -sf "$SCRIPT_DIR/$config_file" ~/.config/starship.toml

    echo "✓ Starship configuration linked"
}

# Main setup function
main() {
    install_starship
    setup_starship_config

    echo ""
    echo "=========================================="
    echo "    Starship Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Starship prompt is now available for both bash and zsh!"
    echo ""
    echo "Features:"
    echo "  - Git branch and status indicators"
    echo "  - Language/runtime version display"
    echo "  - Docker context awareness"
    echo "  - Consistent appearance across shells"
    echo ""
    echo "The prompt will activate automatically in new shell sessions."
    echo ""
}

# Run main function with all arguments
main "$@"