# ~/.bashrc

[[ $- != *i* ]] && return
eval "$(starship init bash)"

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

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
export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

if [ -z "$SSH_AUTH_SOCK" ]; then
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519 &> /dev/null
fi

