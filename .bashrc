# ~/.bashrc

[[ $- != *i* ]] && return
eval "$(starship init bash)"

PS1='[\u@\h \W]\$ '

alias neofetch="fastfetch"
alias ls='ls --color=auto'
alias sl="ls --color=auto"
alias calculator="gnome-calculator"
alias dotfiles="/usr/bin/git --git-dir=$HOME/Devworx/dotfiles --work-tree=$HOME"
alias vim="/usr/bin/nvim"
alias vi="/usr/bin/nvim"
alias tlp-stat="sudo tlp-stat"
alias matrix="cmatrix"
alias yt="yt-dlp"
alias hostname="cat /etc/hostname"
alias Notes="cd ~/Devworx/Notes && vim bootstrap.md"
alias mvnc='function _mvnc() { mvn archetype:generate -DgroupId=com.bigobrains -DartifactId=$1 -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false; }; _mvnc'

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

if [[ -z "$NVIM" ]]; then
	fastfetch
fi

if [ -z "$SSH_AUTH_SOCK" ]; then
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519 &> /dev/null
fi

