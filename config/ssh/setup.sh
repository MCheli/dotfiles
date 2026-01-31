#!/bin/bash
# SSH configuration setup

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SSH_CONFIG_TEMPLATE="$DOTFILES_DIR/templates/ssh_config.template"

echo "Setting up SSH configuration..."

# Create SSH directory if it doesn't exist
if [[ ! -d ~/.ssh ]]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo "✓ Created ~/.ssh directory"
fi

# Setup SSH config if template exists
if [[ -f "$SSH_CONFIG_TEMPLATE" ]]; then
    if [[ ! -f ~/.ssh/config ]]; then
        echo "Installing SSH configuration template..."
        cp "$SSH_CONFIG_TEMPLATE" ~/.ssh/config
        chmod 600 ~/.ssh/config
        echo "✓ SSH configuration installed to ~/.ssh/config"
        echo ""
        echo "⚠️  Please review and customize ~/.ssh/config:"
        echo "   - Add your server configurations"
        echo "   - Update host names, users, and key paths"
        echo "   - Remove unused example configurations"
    else
        echo "SSH config already exists. Template available at:"
        echo "   $SSH_CONFIG_TEMPLATE"
        echo ""
        echo "To merge with existing config:"
        echo "   cat $SSH_CONFIG_TEMPLATE >> ~/.ssh/config"
    fi
else
    echo "Warning: SSH config template not found"
    exit 1
fi

# Set proper permissions on SSH directory and files
chmod 700 ~/.ssh
find ~/.ssh -type f -exec chmod 600 {} \;
find ~/.ssh -type f -name "*.pub" -exec chmod 644 {} \;

echo ""
echo "SSH setup complete!"
echo ""
echo "Security recommendations:"
echo "1. Generate SSH keys if you haven't already:"
echo "   ssh-keygen -t ed25519 -C \"your.email@example.com\""
echo ""
echo "2. Add your public key to remote servers:"
echo "   ssh-copy-id user@hostname"
echo ""
echo "3. Test your configuration:"
echo "   ssh -T git@github.com  # For GitHub"
echo ""
echo "4. Use ssh-agent for key management:"
echo "   ssh-add ~/.ssh/id_ed25519"