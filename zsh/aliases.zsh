# ===== Basic Navigation =====
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# ===== File Operations =====
alias ll='ls -lah'
alias la='ls -la'
alias l='ls -CF'
alias lt='ls -ltr'
alias lh='ls -lah'
alias tree='tree -C'

# Better defaults
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -i'
alias mkdir='mkdir -pv'

# ===== System Information =====
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias top='htop'

# Network
alias ping='ping -c 5'
alias ports='netstat -tulanp'
alias myip='curl -s ifconfig.me'
alias localip='hostname -I | cut -d" " -f1'

# ===== Development =====
# Git shortcuts (supplement to gitconfig aliases)
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias glog='git log --oneline --graph --decorate'

# Docker
alias dk='docker'
alias dkc='docker-compose'
alias dkps='docker ps'
alias dkim='docker images'
alias dkrm='docker rm'
alias dkrmi='docker rmi'

# Node.js/NPM
alias ni='npm install'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'
alias nrd='npm run dev'

# Python
alias py='python'
alias py3='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# ===== Text Processing =====
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cat='cat -n'

# ===== Archives =====
alias tarx='tar -xvf'
alias tarc='tar -cvf'
alias tarz='tar -czvf'
alias untar='tar -xvf'

# ===== Process Management =====
alias psg='ps aux | grep'
alias killall='killall -v'

# ===== Shortcuts =====
# Quick edit common files
alias zshrc='${=EDITOR} ~/.zshrc'
alias vimrc='${=EDITOR} ~/.vimrc'
alias hosts='sudo ${=EDITOR} /etc/hosts'

# Quick reload
alias reload='source ~/.zshrc'

# History
alias h='history'
alias hgrep='history | grep'

# Clear screen properly
alias c='clear'
alias cls='clear'

# ===== Platform-specific Aliases =====
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific
    alias flush='dscacheutil -flushcache && killall -HUP mDNSResponder'
    alias lscleanup='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder'
    alias show='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
    alias hide='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
    alias brewup='brew update && brew upgrade'
    alias o='open'
    alias copy='pbcopy'
    alias paste='pbpaste'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux specific
    alias open='xdg-open'
    alias copy='xclip -selection clipboard'
    alias paste='xclip -selection clipboard -o'
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
    alias aptup='sudo apt update && sudo apt upgrade'
    alias install='sudo apt install'
    alias search='apt search'
fi