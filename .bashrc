#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
eval "$(starship init bash)"

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# Aliases
alias calculator="gnome-calculator"
alias neofetch="fastfetch"
alias dotfiles='/usr/bin/git --git-dir=$HOME/Devworx/dotfiles --work-tree=$HOME'
alias vim="/usr/bin/nvim"
fastfetch

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH="$JAVA_HOME/bin:$PATH"

jexec() {
    mvn exec:java -Dexec.mainClass="$1"
}
