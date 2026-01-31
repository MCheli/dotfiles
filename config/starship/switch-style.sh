#!/bin/bash
# Switch between Starship styles

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌟 Starship Style Switcher"
echo ""
echo "Available styles:"
echo "  1) Colorful - Colorful segments like P10K rainbow"
echo "  2) Lean - Minimalist single-line like P10K lean"
echo "  3) Pure - Clean two-line like P10K pure"
echo "  4) Powerline - Classic powerline with arrows"
echo ""

while true; do
    read -p "Choose style [1-4]: " choice
    case $choice in
        1)
            config_file="starship.toml"
            style_name="Colorful"
            break
            ;;
        2)
            config_file="lean.toml"
            style_name="Lean"
            break
            ;;
        3)
            config_file="pure.toml"
            style_name="Pure"
            break
            ;;
        4)
            config_file="powerline.toml"
            style_name="Powerline"
            break
            ;;
        *)
            echo "Please enter 1, 2, 3, or 4"
            ;;
    esac
done

# Create config directory if it doesn't exist
mkdir -p ~/.config

# Backup current config if it exists
if [[ -f ~/.config/starship.toml ]]; then
    cp ~/.config/starship.toml ~/.config/starship.toml.backup.$(date +%Y%m%d_%H%M%S)
    echo "Previous config backed up"
fi

# Switch to new style
ln -sf "$SCRIPT_DIR/$config_file" ~/.config/starship.toml

echo "✓ Switched to $style_name style"
echo ""
echo "The new prompt will appear in your next shell session."
echo "To see it immediately, run: exec bash  (or exec zsh)"