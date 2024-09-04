# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"


# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"
# ZSH_THEME="avit"
# ZSH_THEME="miloshadzic"
# ZSH_THEME="agnoster"
# check `formation/spaceship_config` for spaceship settings

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  docker
  autojump
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#

alias delete-all-local-branches='git branch | egrep -v "(^\*|master)" | xargs git branch -D'
alias delete-merged='ggl && git branch --merged | egrep -v "(^\*|master|dev|release|codus)" | xargs git branch -d && git fetch --all --prune'
alias yas="yarn start"
alias yad="yarn dev"
alias yat="yarn test"
alias yatch="yarn test --watch"
alias cz="code ~/.zshrc"
alias awslp="aws-profile && aws-login"
alias aws-login=aws-login-fn


# =====  FUNCTIONS  =====
# aws-login-tool alias
aws-login-fn() {
  echo "aws-login getting available roles"
  local selected_role=$(aws-login-tool list-roles -m "${@:1}" | peco --layout bottom-up) || return

  if [[ ! -z $selected_role ]]; then
    local account_id=$(echo "$selected_role" | awk '{print $2}')
    local role=$(echo "$selected_role" | awk '{print $4}')

    unset -m "AWS_*"  # prevent aws tokens stored in env variables
    export AWS_PROFILE=$role@$account_id

    echo "aws-login using $AWS_PROFILE"
    aws-login-tool login -a "$account_id" -r "$role" -d 14400 $@
  else
    echo "aws-login requires a role and account – no role selected"
  fi
}
function aws-profile() {
  export AWS_PROFILE="$(grep '\[.*\]' ~/.aws/credentials | tr -d '[-]' | fzf)"
}
# short for fixup_and_rebase
frb() {
  git commit --fixup=$1 && git rebase -i --autosquash $1~
}
gppr() {
  branch=$(git symbolic-ref -q --short HEAD)
  result=$(git push origin $branch 2>&1)
  # url=$(echo "$result" | grep -o 'http\S*')
  url=$(echo "$result" | grep -o 'https://stash\.int\.klarna\.net\S*')
  if [ $url ]; then
    case "$OSTYPE" in
      darwin*)  open $url ;;
      linux*)   xdg-open $url > /dev/null 2>/dev/null ;;
      msys*)    start $url ;;
      *)        echo "Unknown OS: $OSTYPE" ;;
    esac
    echo $result
    echo "Opened PR in your browser."
  else
    echo $result
  fi
}
cj() {
  j $1 && code .
}
uncommited_changes() {
  echo 'repos with uncommitted changes: '
  for dir in * ; do
    if [[ -d $dir  ]] && [[ -d $dir/.git ]]; then
      (
        cd $dir
        # do we have any change on repo?
        if [ 1 -ne `git status | grep 'nothing to commit' | wc -l` ]; then
          echo $dir
          git status -s
        fi
      );
    fi
  done

  echo
  echo 'repos with unpushed changes: '

  for dir in * ; do
    if [[ -d $dir  ]] && [[ -d $dir/.git ]]; then
      (
        cd $dir
        # do we have any unpushed commit on repo?
        if [ 0 -ne `git status | grep 'Your branch is ahead of' | wc -l` ]; then
          echo $dir
        fi
      );
    fi
  done

  echo
  echo 'repos on feature-branches: '

  for dir in * ; do
    if [[ -d $dir  ]] && [[ -d $dir/.git ]]; then
      (
        cd $dir
        # are we on master branch?
        if [ 1 -ne `git status | grep 'On branch master' | wc -l` ]; then
          echo $dir": "$(git rev-parse --abbrev-ref HEAD)
        fi
      );
    fi
  done
}

# fh - repeat history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -r 's/ *[0-9]*\*? *//' | sed -r 's/\\/\\\\/g')
}

source <(fzf --zsh)
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

