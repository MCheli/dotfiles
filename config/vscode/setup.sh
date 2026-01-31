#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== VS Code Setup ==="

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Skip on SSH sessions by default
if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]] && [[ "$1" != "--force" ]]; then
    echo "SSH session detected - skipping VS Code setup"
    echo "Run with --force to install anyway"
    exit 0
fi

# Convert architecture for VS Code downloads
case "$ARCH" in
    x86_64) VSCODE_ARCH="x64" ;;
    arm64|aarch64) VSCODE_ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Install VS Code based on OS
install_vscode() {
    if command -v code &>/dev/null; then
        echo "VS Code is already installed"
        return 0
    fi

    echo "Installing Visual Studio Code..."

    case "$OS" in
        Darwin)
            # macOS - Use Homebrew if available, otherwise direct download
            if command -v brew &>/dev/null; then
                brew install --cask visual-studio-code
            else
                echo "Downloading VS Code for macOS..."
                DOWNLOAD_URL="https://code.visualstudio.com/sha/download?build=stable&os=darwin-universal"
                curl -fsSL "$DOWNLOAD_URL" -o /tmp/vscode.zip
                unzip -q /tmp/vscode.zip -d /tmp/
                mv "/tmp/Visual Studio Code.app" /Applications/
                rm /tmp/vscode.zip
                # Add code command to PATH
                ln -sf "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code 2>/dev/null || true
            fi
            ;;

        Linux)
            # Detect Linux distribution
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                DISTRO="$ID"
            else
                echo "Cannot detect Linux distribution"
                exit 1
            fi

            case "$DISTRO" in
                ubuntu|debian|raspbian)
                    # Ubuntu/Debian - use official Microsoft repository
                    echo "Installing VS Code via APT..."

                    # Add Microsoft GPG key
                    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg

                    # Add repository
                    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

                    # Update and install
                    sudo apt-get update
                    sudo apt-get install -y code
                    ;;

                fedora|rhel|centos)
                    # Fedora/RHEL - use official Microsoft repository
                    echo "Installing VS Code via DNF/YUM..."
                    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo

                    if command -v dnf &>/dev/null; then
                        sudo dnf install -y code
                    else
                        sudo yum install -y code
                    fi
                    ;;

                arch|manjaro)
                    # Arch Linux - use AUR or direct download
                    if command -v yay &>/dev/null; then
                        yay -S visual-studio-code-bin
                    elif command -v paru &>/dev/null; then
                        paru -S visual-studio-code-bin
                    else
                        echo "Installing VS Code via direct download..."
                        DOWNLOAD_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-${VSCODE_ARCH}"
                        curl -fsSL "$DOWNLOAD_URL" -o /tmp/vscode.tar.gz
                        sudo tar -xzf /tmp/vscode.tar.gz -C /opt/
                        sudo mv /opt/VSCode-linux-${VSCODE_ARCH} /opt/vscode
                        sudo ln -sf /opt/vscode/bin/code /usr/local/bin/code
                        rm /tmp/vscode.tar.gz
                    fi
                    ;;

                *)
                    echo "Unsupported Linux distribution: $DISTRO"
                    echo "Please install VS Code manually and re-run this script"
                    exit 1
                    ;;
            esac
            ;;

        *)
            echo "Unsupported operating system: $OS"
            exit 1
            ;;
    esac

    # Verify installation
    if command -v code &>/dev/null; then
        echo "VS Code installed successfully"
    else
        echo "VS Code installation failed"
        exit 1
    fi
}

# Get VS Code user settings directory
get_vscode_settings_dir() {
    case "$OS" in
        Darwin)
            echo "$HOME/Library/Application Support/Code/User"
            ;;
        Linux)
            echo "$HOME/.config/Code/User"
            ;;
        *)
            echo "Unsupported OS for VS Code settings: $OS"
            exit 1
            ;;
    esac
}

# Setup VS Code configuration
setup_vscode_config() {
    local settings_dir
    settings_dir="$(get_vscode_settings_dir)"

    echo "Setting up VS Code configuration..."

    # Create settings directory if it doesn't exist
    mkdir -p "$settings_dir"

    # Backup existing settings
    if [[ -f "$settings_dir/settings.json" && ! -L "$settings_dir/settings.json" ]]; then
        echo "Backing up existing settings.json"
        mv "$settings_dir/settings.json" "$settings_dir/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Create symlink to our settings
    echo "Linking VS Code settings..."
    ln -sf "$SCRIPT_DIR/settings.json" "$settings_dir/settings.json"

    echo "VS Code settings configured"
}

# Install VS Code extensions
install_extensions() {
    if [[ ! -f "$SCRIPT_DIR/extensions.txt" ]]; then
        echo "Extensions file not found: $SCRIPT_DIR/extensions.txt"
        return
    fi

    echo "Installing VS Code extensions..."

    # Read extensions from file and install
    while IFS= read -r extension || [[ -n "$extension" ]]; do
        # Skip comments and empty lines
        [[ "$extension" =~ ^#.*$ ]] || [[ -z "$extension" ]] && continue

        echo "Installing extension: $extension"
        code --install-extension "$extension" --force 2>/dev/null || {
            echo "Failed to install extension: $extension"
        }
    done < "$SCRIPT_DIR/extensions.txt"

    echo "Extension installation complete"
}

# Main setup function
main() {
    # Check if VS Code setup should be skipped
    if [[ "$1" == "--skip" ]]; then
        echo "Skipping VS Code setup as requested"
        return 0
    fi

    # Install VS Code
    install_vscode

    # Setup configuration
    setup_vscode_config

    # Install extensions
    install_extensions

    echo ""
    echo "=========================================="
    echo "    VS Code Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Configuration applied:"
    echo "  - Dracula theme with VS Code icons"
    echo "  - MesloLGS Nerd Font Mono for editor and terminal"
    echo "  - Essential extensions installed"
    echo "  - Terminal configured to use zsh with your shell config"
    echo ""
    echo "Launch VS Code with: code"
    echo ""
}

# Run main function with all arguments
main "$@"