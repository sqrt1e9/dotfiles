# ~/.bashrc

[[ $- != *i* ]] && return
eval "$(starship init bash)"

PS1='[\u@\h \W]\$ '

GPG_TTY=$(tty)

alias neofetch="fastfetch"
alias ls='ls --color=auto'
alias dotfiles="/usr/bin/git --git-dir=$HOME/Devworx/dotfiles --work-tree=$HOME"
alias vim="/usr/bin/nvim"
alias vi="/usr/bin/nvim"
alias tlp-stat="sudo tlp-stat"
alias matrix="cmatrix"
alias yt="yt-dlp"
alias hostname="cat /etc/hostname"
alias Notes="cd ~/Devworx/Notes && vim bootstrap.md"
alias mvnc='function _mvnc() { mvn archetype:generate -DgroupId=com.bigobrains -DartifactId=$1 -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false; }; _mvnc'
alias kvmsh="kvmsh.sh"
alias chatgpt="chatgpt.sh"
alias kvmview="virt-viewer"
alias fw="fwupdmgr"
alias sha="sha256sum"
alias hi="cowsay \"Hi Arthana\""
alias fire="cacafire"
alias sl="sl -le"
alias fc-scan="fc-scan --format \"%{family}\n\""

export GPG_TTY
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

~/.local/bin/gpg-unlock.sh

if [[ -z "$NVIM" ]]; then
	fastfetch
fi

if [ -z "$SSH_AUTH_SOCK" ]; then
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519 &> /dev/null
fi

export GPG_TTY=$(tty)
