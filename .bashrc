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
alias tlp-stat="sudo tlp-stat"
alias matrix="cmatrix"
alias train="sl"
alias hi="cowsay Hi Arthana"
alias arthana="toilet ARTHANA"
alias ocean="asciiquarium"
fastfetch

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH="$JAVA_HOME/bin:$PATH"

jexec() {
    mvn exec:java -Dexec.mainClass="$1"
}

gpt() {
    local openai_api_key=$(bit get item openai.com | jq -r .fields[0].value)
    chatblade --openai-api-key "$openai_api_key" "$@"
}

bit() {
    local bw_session_key=$(cat "$HOME/.bitwarden-session-key.key")
    bw --session "$bw_session_key" "$@"
}
