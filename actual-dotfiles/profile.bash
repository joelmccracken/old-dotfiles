#!/usr/bin/env bash
export PATH=/usr/local/bin:$PATH
# add emacs
export PATH=/Applications/Emacs.app/Contents/MacOS:$PATH
# add emacsclient, etc
export PATH=/Applications/Emacs.app/Contents/MacOS/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=~/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=$HOME/.cabal/bin:$PATH

export PATH="/opt/homebrew-cask/Caskroom/racket/6.1.1/Racket\ v6.1.1/bin/raco:$PATH"

# export PATH="/usr/local/Cellar/ruby20/2.0.0-p481/bin:$PATH"

export GIT_EDITOR='emacsclient -s server'
export EDITOR=$GIT_EDITOR



git-on-branch () {
    git stash
    ORIGINAL_BRANCH=`git branch | grep \* | sed 's/\*[[:space:]]//'`
    git checkout $1
    $2
    git checkout $ORIGINAL_BRANCH
    git stash pop
}

alias vesh="cd ~/vagrant-environment/apangea; vagrant ssh"

shopt -s extglob

ssh-add `ls ~/var/secrets/id_rsa* | grep -v .pub` > /dev/null 2>&1

function aalias {
    mkdir -p ~/.bash_it/custom/
    echo "alias ${1}='${@:2}'" >> ~/.bash_it/custom/aliases.bash
    source ~/.bash_it/custom/aliases.bash
}

function on-branch {
    local original_branch=$(git branch | sed -n '/\* /s///p')
    git checkout $1 && \
        bash && \
        git checkout $original_branch
}

function alerts_prompt {
    cat ~/var/alerts/number
}

function alerts {
    cat ~/var/alerts/alerts
}

function jnm_prompt_command {
    PS1="\n$(alerts_prompt) ${yellow}$(ruby_version_prompt) ${purple}\h ${reset_color}in ${green}\w\n${bold_cyan}$(scm_char)${green}$(scm_prompt_info) ${green}→${reset_color} "
}
PROMPT_COMMAND=jnm_prompt_command;

function save(){ echo "$@" >> ~/var/saved_commands; }

export HISTCONTROL=erasedups
export HISTSIZE=10000
shopt -s histappend

