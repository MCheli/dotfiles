# MCheli's Shared Shell Exports
# Compatible with both bash and zsh

# ===== Editor Configuration =====
export EDITOR="vim"
export VISUAL="$EDITOR"

# ===== History Configuration =====
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL="ignoreboth:erasedups"

# ===== Development Environment =====
# Node.js
export NODE_ENV="development"

# Python
export PYTHONPATH="$HOME/.local/lib/python3/site-packages:$PYTHONPATH"
export PIP_REQUIRE_VIRTUALENV=false

# Go (if installed)
if command -v go >/dev/null 2>&1; then
    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"
fi

# Rust (if installed)
if [ -d "$HOME/.cargo" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# ===== PATH Configuration =====
# Local binaries
export PATH="$HOME/.local/bin:$PATH"

# Platform-specific PATH setup
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific paths
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
    if [ -d "/usr/local/bin" ]; then
        export PATH="/usr/local/bin:$PATH"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux specific paths
    export PATH="/usr/local/bin:$PATH"
fi

# ===== Color Support =====
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# ===== Less Configuration =====
export LESS="-R -i -M -S -x4"
export LESSHISTFILE="-"

# ===== Development Tools =====
# Docker
if command -v docker >/dev/null 2>&1; then
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
fi

# ===== Locale =====
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8