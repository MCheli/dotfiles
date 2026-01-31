#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Dotfiles Setup ==="
echo "Dotfiles directory: $DOTFILES_DIR"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"
echo "Detected OS: $OS ($ARCH)"

# Detect if running on Raspberry Pi
is_raspberry_pi() {
    [[ -f /proc/device-tree/model ]] && grep -qi "raspberry" /proc/device-tree/model
}

if is_raspberry_pi; then
    echo "Detected: Raspberry Pi"
fi

# Install Nerd Font on Linux (for local desktop use)
install_nerd_font_linux() {
    if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        echo "SSH session detected - skipping font installation (install on your local machine instead)"
        return
    fi

    # Check if running a desktop environment
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
        echo "No display detected - skipping font installation"
        return
    fi

    echo "Installing MesloLGS Nerd Font..."
    FONT_DIR="${HOME}/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    # Download Meslo Nerd Font
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    TEMP_DIR=$(mktemp -d)

    if curl -fsSL "$FONT_URL" -o "$TEMP_DIR/Meslo.zip"; then
        unzip -q "$TEMP_DIR/Meslo.zip" -d "$TEMP_DIR/meslo"
        cp "$TEMP_DIR/meslo"/*.ttf "$FONT_DIR/" 2>/dev/null || true
        rm -rf "$TEMP_DIR"

        # Refresh font cache
        if command -v fc-cache &>/dev/null; then
            fc-cache -f "$FONT_DIR"
        fi
        echo "Nerd Font installed to $FONT_DIR"
    else
        echo "Warning: Could not download Nerd Font"
    fi
}

# Install dependencies based on OS
install_dependencies() {
    if [[ "$OS" == "Darwin" ]]; then
        # macOS
        if ! command -v brew &>/dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
        fi

        echo "Installing packages via Homebrew..."
        brew install powerlevel10k zsh-autosuggestions zsh-syntax-highlighting

        # Install Nerd Font (only on local machine, not SSH)
        if [[ -z "$SSH_CLIENT" ]]; then
            brew install --cask font-meslo-lg-nerd-font

            # Auto-configure Terminal.app
            if [[ -f "$DOTFILES_DIR/scripts/configure-terminal-app.sh" ]]; then
                echo "Configuring Terminal.app..."
                bash "$DOTFILES_DIR/scripts/configure-terminal-app.sh"
            fi
        fi

    elif [[ "$OS" == "Linux" ]]; then
        # Linux (Ubuntu, Debian, Raspberry Pi OS)
        echo "Installing dependencies..."

        if command -v apt-get &>/dev/null; then
            # Debian/Ubuntu/Raspberry Pi OS
            sudo apt-get update
            sudo apt-get install -y zsh git curl unzip fontconfig

        elif command -v dnf &>/dev/null; then
            # Fedora/RHEL
            sudo dnf install -y zsh git curl unzip fontconfig

        elif command -v yum &>/dev/null; then
            # Older RHEL/CentOS
            sudo yum install -y zsh git curl unzip fontconfig

        elif command -v pacman &>/dev/null; then
            # Arch Linux
            sudo pacman -S --noconfirm zsh git curl unzip fontconfig
        fi

        # Install Powerlevel10k
        if [[ ! -d "${HOME}/.powerlevel10k" ]]; then
            echo "Installing Powerlevel10k..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
        else
            echo "Updating Powerlevel10k..."
            git -C ~/.powerlevel10k pull --depth=1 2>/dev/null || true
        fi

        # Install zsh-autosuggestions
        if [[ ! -d "${HOME}/.zsh-autosuggestions" ]]; then
            echo "Installing zsh-autosuggestions..."
            git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh-autosuggestions
        fi

        # Install zsh-syntax-highlighting
        if [[ ! -d "${HOME}/.zsh-syntax-highlighting" ]]; then
            echo "Installing zsh-syntax-highlighting..."
            git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh-syntax-highlighting
        fi

        # Install Nerd Font for desktop Linux
        install_nerd_font_linux
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
    local zsh_path
    zsh_path="$(which zsh)"

    if [[ "$SHELL" != *"zsh"* ]]; then
        echo "Setting zsh as default shell..."

        # Add zsh to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi

        # Change shell
        if chsh -s "$zsh_path"; then
            echo "Default shell changed to zsh"
        else
            echo "Warning: Could not change default shell. You may need to run: chsh -s $zsh_path"
        fi
    else
        echo "zsh is already the default shell"
    fi
}

# Print post-install instructions
print_instructions() {
    echo ""
    echo "=========================================="
    echo "         Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Restart your terminal or run:"
    echo "   exec zsh"
    echo ""
    echo "2. The Powerlevel10k configuration wizard will start automatically."
    echo "   Or run manually: p10k configure"
    echo ""

    if [[ "$OS" == "Darwin" ]]; then
        if [[ -z "$SSH_CLIENT" ]]; then
            echo "3. Terminal.app should be auto-configured. If not:"
            echo "   - Open Terminal → Preferences → Profiles"
            echo "   - Select 'Dracula' and click 'Default'"
            echo "   - Set font to 'MesloLGS Nerd Font Mono'"
            echo ""
        fi
    elif [[ "$OS" == "Linux" ]]; then
        if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
            echo "3. You're on SSH - fonts are rendered by your LOCAL terminal."
            echo "   Make sure your local terminal has a Nerd Font installed."
            echo ""
        else
            echo "3. Set your terminal font to 'MesloLGS Nerd Font Mono':"
            echo "   - GNOME Terminal: Preferences → Profile → Custom font"
            echo "   - Konsole: Settings → Edit Current Profile → Appearance"
            echo "   - LXTerminal: Edit → Preferences → Style"
            echo ""
        fi
    fi

    echo "4. After configuring p10k, save your config to dotfiles:"
    echo "   cp ~/.p10k.zsh $DOTFILES_DIR/zsh/p10k.zsh"
    echo ""
}

# Setup additional configurations
setup_configs() {
    echo "Setting up additional configurations..."

    # Git configuration
    if [[ -f "$DOTFILES_DIR/config/git/setup.sh" ]]; then
        echo "Setting up Git configuration..."
        bash "$DOTFILES_DIR/config/git/setup.sh"
    fi

    # Vim configuration
    if [[ -f "$DOTFILES_DIR/config/vim/setup.sh" ]]; then
        echo "Setting up Vim configuration..."
        bash "$DOTFILES_DIR/config/vim/setup.sh"
    fi

    # SSH configuration (optional)
    echo ""
    read -p "Setup SSH configuration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f "$DOTFILES_DIR/config/ssh/setup.sh" ]]; then
            bash "$DOTFILES_DIR/config/ssh/setup.sh"
        fi
    fi
}

# Main
main() {
    install_dependencies
    create_symlinks
    set_default_shell
    setup_configs
    print_instructions
}

main "$@"
