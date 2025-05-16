# ~/.bashrc

[[ $- != *i* ]] && return
eval "$(starship init bash)"

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# Aliases
alias calculator="gnome-calculator"
alias neofetch="fastfetch"
alias dotfiles="/usr/bin/git --git-dir=$HOME/Devworx/dotfiles --work-tree=$HOME"
alias vim="/usr/bin/nvim"
alias vi="/usr/bin/nvim"
alias tlp-stat="sudo tlp-stat"
alias matrix="cmatrix"
alias train="sl"
alias Hi="cowsay Hi Arthana"
alias ocean="asciiquarium"
alias yt="yt-dlp"
alias hostname="cat /etc/hostname"
fastfetch

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$PATH"

jexec() {
    mvn exec:java -Dexec.mainClass="$1"
}

export PATH="$HOME/.cargo/bin:$PATH"
