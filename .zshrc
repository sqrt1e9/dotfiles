# ~/.zshrc

# ===== Interactive shell check =====
# Zsh uses $- too, but no need to return; instead set options only for interactive shells.
[[ $- != *i* ]] && return

# ===== Starship prompt =====
eval "$(starship init zsh)"

# ===== Prompt (Starship overrides this, so optional) =====
# PROMPT='[%n@%m %1~]$ '

# ===== GPG / TTY =====
export GPG_TTY=$(tty)

# ===== Aliases =====
alias neofetch="fastfetch"
alias ls='ls --color=auto'

alias dotfiles="/usr/bin/git --git-dir=$HOME/Devworx/dotfiles --work-tree=$HOME"

alias vim="/usr/bin/nvim"
alias vi="/usr/bin/nvim"

alias tlp-stat="sudo tlp-stat"
alias matrix="cmatrix"
alias yt="yt-dlp"
alias hostname="cat /etc/hostname"

alias Notes='cd ~/Devworx/Notes && vim bootstrap.md'

# mvnc function turned into proper zsh function
mvnc() {
    mvn archetype:generate \
        -DgroupId=com.bigobrains \
        -DartifactId="$1" \
        -DarchetypeArtifactId=maven-archetype-quickstart \
        -DinteractiveMode=false
}

alias kvmsh="kvmsh.sh"
alias chatgpt="chatgpt.sh"
alias kvmview="virt-viewer"
alias fw="fwupdmgr"
alias sha="sha256sum"
alias hi='cowsay "Hi Arthana"'
alias fire="cacafire"
alias sl="sl -le"
alias fc-scan='fc-scan --format "%{family}\n"'

# ===== Environment Variables =====
export CACA_DRIVER=ncurses cacafire
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/lib/qt6/bin:$PATH"

export LIBVIRT_DEFAULT_URI=qemu:///system
export QT_STYLE_OVERRIDE=dark
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
export GTK_THEME=Adwaita:dark
export SYSTEMD_EDITOR=vim

# ===== Run gpg unlock script =====
~/.local/bin/gpg-unlock.sh

# ===== Fastfetch when not in Neovim terminal =====
if [[ -z "$NVIM" ]]; then
    fastfetch
fi

# ===== Auto-start ssh-agent if missing =====
if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519 &> /dev/null
fi

# ===== Zsh improvements =====

# Extended globbing (more powerful patterns)
setopt EXTENDED_GLOB

# Auto-cd: just type a folder name to cd into it
setopt AUTO_CD

# Correct directory names on cd
setopt CORRECT

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

# Enable completion system
autoload -Uz compinit
compinit

