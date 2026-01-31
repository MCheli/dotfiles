# MCheli's Shared Shell Functions
# Compatible with both bash and zsh

# ===== Useful Functions =====

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find and kill process by name
killp() {
    if [ $# -eq 0 ]; then
        echo "Usage: killp <process_name>"
        return 1
    fi
    ps aux | grep -v grep | grep "$1" | awk '{print $2}' | xargs kill -9
}

# Quick backup of a file
backup() {
    if [ $# -eq 0 ]; then
        echo "Usage: backup <file>"
        return 1
    fi
    cp "$1" "$1.backup.$(date +%Y%m%d-%H%M%S)"
}

# Create a quick HTTP server from current directory
serve() {
    local port=${1:-8000}
    echo "Starting HTTP server on port $port..."
    echo "Access at: http://localhost:$port"
    if command -v python3 &>/dev/null; then
        python3 -m http.server "$port"
    elif command -v python &>/dev/null; then
        python -m SimpleHTTPServer "$port"
    elif command -v ruby &>/dev/null; then
        ruby -run -e httpd . -p "$port"
    else
        echo "No suitable HTTP server found (need python, python3, or ruby)"
        return 1
    fi
}

# Weather function
weather() {
    local city="${1:-}"
    if [[ -n "$city" ]]; then
        curl -s "wttr.in/$city"
    else
        curl -s "wttr.in"
    fi
}

# Get public IP (function version)
getmyip() {
    curl -s ifconfig.me
}

# Find files by name
ff() {
    if [ $# -eq 0 ]; then
        echo "Usage: ff <filename_pattern>"
        return 1
    fi
    find . -type f -iname "*$1*"
}

# Find directories by name
fd() {
    if [ $# -eq 0 ]; then
        echo "Usage: fd <dirname_pattern>"
        return 1
    fi
    find . -type d -iname "*$1*"
}

# Grep with context and color
search() {
    if [ $# -eq 0 ]; then
        echo "Usage: search <pattern> [directory]"
        return 1
    fi
    local pattern="$1"
    local dir="${2:-.}"
    grep -r --color=auto -n -C 3 "$pattern" "$dir"
}

# Quick note-taking
note() {
    local note_file="$HOME/notes.txt"
    if [ $# -eq 0 ]; then
        # Show recent notes
        if [ -f "$note_file" ]; then
            tail -20 "$note_file"
        else
            echo "No notes found"
        fi
    else
        # Add note with timestamp
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$note_file"
        echo "Note added: $*"
    fi
}

# Docker helpers
docker-clean() {
    echo "Cleaning up Docker..."
    docker system prune -f
    docker volume prune -f
    docker image prune -a -f
}

docker-stop-all() {
    if [ "$(docker ps -q)" ]; then
        docker stop $(docker ps -q)
    else
        echo "No running containers to stop"
    fi
}

docker-rm-all() {
    if [ "$(docker ps -aq)" ]; then
        docker rm $(docker ps -aq)
    else
        echo "No containers to remove"
    fi
}

# Git helpers
gitclean() {
    git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
}

gitsize() {
    git count-objects -vH
}

# System helpers
memtop() {
    ps aux --sort=-%mem | head -20
}

cputop() {
    ps aux --sort=-%cpu | head -20
}

# URL encode/decode
urlencode() {
    python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

urldecode() {
    python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))" "$1"
}

# Random password generator
genpass() {
    local length=${1:-16}
    openssl rand -base64 $((length * 3 / 4)) | tr -d "=+/" | cut -c1-${length}
}