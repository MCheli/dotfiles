# MCheli's Dotfiles

Mark Cheli's cross-platform dotfiles setup with automated installation for macOS, Linux, and remote servers. Supports both **bash** and **zsh** with shared configuration.

## Features

- **Cross-platform**: Works on macOS, Ubuntu, Debian, Fedora, Arch Linux, and Raspberry Pi
- **Dual shell support**: Both bash and zsh configurations with shared components
- **One-line install**: Bootstrap from any remote server
- **Beautiful terminal**: Powerlevel10k theme for zsh, colorized prompt for bash
- **Smart fallbacks**: Works even when dependencies aren't available
- **SSH-aware**: Different behavior for local vs remote installations
- **Shell choice**: Interactive prompt to choose your preferred shell

## Quick Install

### Local Installation

```bash
git clone https://github.com/MCheli/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/setup.sh
```

### Remote Server (One-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/MCheli/dotfiles/main/scripts/bootstrap.sh | bash
```

or

```bash
wget -qO- https://raw.githubusercontent.com/MCheli/dotfiles/main/scripts/bootstrap.sh | bash
```

## What's Included

### Shell Configuration
- **Bash and Zsh support** with shared configuration
- **Enhanced prompts**: Powerlevel10k (zsh), Starship (both), or colorized fallback
- **Starship prompt** - cross-shell compatible theming with git integration
- **Shared aliases and functions** across both shells
- **Autosuggestions and syntax highlighting** (zsh)
- **Optimized history** settings for both shells
- **Cross-platform PATH** configuration

### Terminal Appearance
- **Dracula theme** for Terminal.app (macOS)
- **MesloLGS Nerd Font** with automatic installation
- **Font fallbacks** for SSH sessions

### Development Tools
- **Git configuration** with useful aliases
- **SSH client** configuration with security defaults
- **Vim/Neovim** setup with sensible defaults
- **Visual Studio Code** with Dracula theme, Nerd Font, and essential extensions
- **Common aliases** and shell functions

## Customization

### Git Configuration
Edit `config/git/gitconfig.template` and add your details:
```bash
cp config/git/gitconfig.template ~/.gitconfig
# Edit ~/.gitconfig with your name and email
```

### Powerlevel10k Theme
After installation, configure your prompt:
```bash
p10k configure
```

Save your configuration to the dotfiles:
```bash
cp ~/.p10k.zsh ~/dotfiles/zsh/p10k.zsh
```

### Starship Prompt
Enhanced cross-shell prompt theming:
```bash
# Manual Starship setup
bash config/starship/setup.sh

# Features:
# - Works in both bash and zsh
# - Git branch and status indicators
# - Language/runtime version display
# - Docker context awareness
# - Consistent appearance across shells
```

### Visual Studio Code
The setup includes optional VS Code configuration:
```bash
# Manual VS Code setup
bash config/vscode/setup.sh

# Skip VS Code setup
bash config/vscode/setup.sh --skip

# Force setup even on SSH sessions
bash config/vscode/setup.sh --force
```

Features included:
- Dracula theme with VS Code icons
- MesloLGS Nerd Font for editor and terminal
- Essential extensions (Python, Git, TypeScript, Docker)
- Terminal integration with shell configuration

### Shell Switching
The setup supports both bash and zsh. During installation, you'll be prompted to choose:

```bash
# Switch shells after installation
exec bash    # Switch to bash
exec zsh     # Switch to zsh

# Change default shell permanently
chsh -s $(which bash)    # Set bash as default
chsh -s $(which zsh)     # Set zsh as default
```

### Custom Aliases
Add personal aliases to:
- `shell/aliases.sh` for both shells
- `~/.bashrc.local` for bash-specific settings
- `~/.zsh_local` for zsh-specific settings

## Platform-Specific Notes

### macOS
- Automatically installs Homebrew if needed
- Configures Terminal.app with Dracula theme
- Installs Nerd Font via Homebrew

### Linux
- Supports apt, dnf, yum, and pacman package managers
- Installs dependencies from distribution repositories
- Downloads Nerd Font for desktop environments

### Remote Servers
- Skips GUI-specific configurations
- Uses fallback prompt when Powerlevel10k unavailable
- Minimal dependencies for fast setup

## Maintenance

### Update Everything
```bash
~/dotfiles/scripts/update.sh
```

### Reinstall
```bash
cd ~/dotfiles
git pull
./scripts/setup.sh
```

### Uninstall
```bash
~/dotfiles/scripts/uninstall.sh
```

## Directory Structure

```
dotfiles/
├── scripts/          # Installation and maintenance scripts
├── shell/           # Shared shell configuration (bash + zsh)
│   ├── aliases.sh   # Common aliases for both shells
│   ├── functions.sh # Utility functions for both shells
│   └── exports.sh   # Environment variables and PATH
├── bash/            # Bash-specific configuration
│   ├── bashrc       # Bash interactive shell config
│   └── bash_profile # Bash login shell config
├── zsh/             # Zsh-specific configuration
│   ├── zshrc        # Zsh interactive shell config
│   └── p10k.zsh     # Powerlevel10k theme settings
├── config/          # Application configurations
│   ├── git/         # Git configuration and templates
│   ├── vim/         # Vim/Neovim configuration
│   ├── vscode/      # Visual Studio Code settings and extensions
│   ├── starship/    # Starship prompt configuration and setup
│   └── ssh/         # SSH client configuration
├── terminal/        # Terminal themes and profiles
└── templates/       # Configuration templates
```

## Troubleshooting

### Font Issues
If you see broken characters:
1. Ensure a Nerd Font is installed on your **local** machine (not the server)
2. Set your terminal to use "MesloLGS Nerd Font Mono"
3. For SSH connections, the font is rendered locally

### Permission Errors
If you get permission errors during installation:
```bash
sudo chown -R $(whoami) ~/dotfiles
chmod +x ~/dotfiles/scripts/*.sh
```

### Shell Not Changed
If zsh doesn't become your default shell:
```bash
chsh -s $(which zsh)
```

## Contributing

Feel free to fork this repository and customize it for your own needs. The setup scripts are designed to be modular and easy to modify.

## License

This dotfiles configuration is released under the MIT License.