#!/bin/bash
# Automatically configure Terminal.app with Dracula theme and Nerd Font

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_FILE="$DOTFILES_DIR/terminal/Dracula.terminal"

echo "Configuring Terminal.app..."

# Import the Dracula theme
if [[ -f "$THEME_FILE" ]]; then
    open "$THEME_FILE"
    sleep 1
fi

# Set Dracula as the default profile and configure font using AppleScript
osascript <<'EOF'
tell application "Terminal"
    -- Get the Dracula settings
    set draculaExists to false
    repeat with s in settings sets
        if name of s is "Dracula" then
            set draculaExists to true
            exit repeat
        end if
    end repeat

    if draculaExists then
        -- Set Dracula as default
        set default settings to settings set "Dracula"
        set startup settings to settings set "Dracula"

        -- Configure the font (MesloLGS Nerd Font Mono, 14pt)
        set font name of settings set "Dracula" to "MesloLGSNerdFontMono-Regular"
        set font size of settings set "Dracula" to 14
    end if
end tell
EOF

echo "Terminal.app configured with Dracula theme and MesloLGS Nerd Font."
echo "Please restart Terminal.app for changes to take effect."
