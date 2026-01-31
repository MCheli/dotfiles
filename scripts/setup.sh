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
    for file in ~/.bashrc ~/.bash_profile ~/.zshrc ~/.p10k.zsh; do
        if [[ -f "$file" && ! -L "$file" ]]; then
            echo "Backing up $file to ${file}.backup"
            mv "$file" "${file}.backup"
        fi
    done

    # Create bash symlinks
    ln -sf "$DOTFILES_DIR/bash/bashrc" ~/.bashrc
    ln -sf "$DOTFILES_DIR/bash/bash_profile" ~/.bash_profile

    # Create zsh symlinks
    ln -sf "$DOTFILES_DIR/zsh/zshrc" ~/.zshrc

    # Create p10k symlink if config exists
    if [[ -f "$DOTFILES_DIR/zsh/p10k.zsh" ]]; then
        ln -sf "$DOTFILES_DIR/zsh/p10k.zsh" ~/.p10k.zsh
    fi

    echo "Shell configuration files linked for both bash and zsh"
}

# Prompt user for shell preference
setup_shell() {
    echo ""
    echo "=========================================="
    echo "         Shell Configuration"
    echo "=========================================="
    echo ""

    # Detect current shell
    local current_shell="$(basename "$SHELL")"
    echo "Current default shell: $current_shell"

    # Check if we're in a non-interactive environment (like curl | bash)
    if [[ ! -t 0 ]] || [[ -n "$SSH_CLIENT" && ! -t 1 ]]; then
        echo ""
        echo "Non-interactive mode detected - keeping current shell ($current_shell)"
        echo "Both bash and zsh configurations are available"
        echo "To change shells later, run: ~/dotfiles/scripts/setup.sh"
        return 0
    fi

    echo ""
    echo "Available options:"
    echo "  1) Keep current shell ($current_shell)"
    echo "  2) Switch to bash"
    echo "  3) Switch to zsh (with Powerlevel10k theme)"
    echo ""

    # Get user choice
    while true; do
        read -p "Choose your shell [1-3]: " choice
        case $choice in
            1)
                echo "Keeping current shell: $current_shell"
                echo "Both bash and zsh configurations are available"
                break
                ;;
            2)
                echo "Switching to bash..."
                change_shell "bash"
                break
                ;;
            3)
                echo "Switching to zsh..."
                change_shell "zsh"
                break
                ;;
            *)
                echo "Please enter 1, 2, or 3"
                ;;
        esac
    done
}

# Change the default shell
change_shell() {
    local new_shell="$1"
    local shell_path

    case "$new_shell" in
        "bash")
            shell_path="$(which bash)"
            ;;
        "zsh")
            shell_path="$(which zsh)"
            ;;
        *)
            echo "Error: Unknown shell $new_shell"
            return 1
            ;;
    esac

    if [[ ! -x "$shell_path" ]]; then
        echo "Error: $new_shell is not installed or not executable"
        return 1
    fi

    # Add shell to /etc/shells if not present
    if ! grep -q "$shell_path" /etc/shells 2>/dev/null; then
        echo "Adding $shell_path to /etc/shells..."
        echo "$shell_path" | sudo tee -a /etc/shells
    fi

    # Change shell
    echo "Changing default shell to $new_shell..."
    if chsh -s "$shell_path"; then
        echo "✓ Default shell changed to $new_shell"
        echo "  Restart your terminal or run 'exec $new_shell' to use the new shell"
    else
        echo "⚠ Warning: Could not change default shell automatically"
        echo "  You can change it manually with: chsh -s $shell_path"
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
    echo "1. Restart your terminal or switch shells:"
    echo "   - For bash: exec bash"
    echo "   - For zsh:  exec zsh"
    echo ""
    echo "2. If using zsh:"
    echo "   - The Powerlevel10k configuration wizard will start automatically"
    echo "   - Or run manually: p10k configure"
    echo "   - If using bash: you'll get a nice colorized prompt automatically"
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

    echo "4. Shell features available in both bash and zsh:"
    echo "   - Shared aliases and functions"
    echo "   - Git shortcuts and development tools"
    echo "   - Cross-platform compatibility"
    echo ""
    echo "5. If you configured p10k, save your config to dotfiles:"
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

    # Check if we're in a non-interactive environment
    if [[ ! -t 0 ]] || [[ -n "$SSH_CLIENT" && ! -t 1 ]]; then
        echo ""
        echo "Non-interactive mode detected - setting up essential configurations"

        # Setup Starship automatically in non-interactive mode
        if [[ -f "$DOTFILES_DIR/config/starship/setup.sh" ]]; then
            echo "Setting up Starship prompt..."
            bash "$DOTFILES_DIR/config/starship/setup.sh"
        fi

        echo "Run ~/dotfiles/scripts/setup.sh locally for full interactive setup"
        echo "Available optional setups:"
        echo "  - bash ~/dotfiles/config/vscode/setup.sh      # VS Code"
        echo "  - bash ~/dotfiles/config/ssh/setup.sh         # SSH config"
        return 0
    fi

    # Starship prompt configuration (optional)
    echo ""
    read -p "Setup Starship prompt (enhanced cross-shell theming)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f "$DOTFILES_DIR/config/starship/setup.sh" ]]; then
            bash "$DOTFILES_DIR/config/starship/setup.sh"
        fi
    fi

    # VS Code configuration (optional)
    echo ""
    read -p "Setup Visual Studio Code? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ -f "$DOTFILES_DIR/config/vscode/setup.sh" ]]; then
            bash "$DOTFILES_DIR/config/vscode/setup.sh"
        fi
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
    setup_shell
    setup_configs
    print_instructions
}

main "$@"
