# shellcheck disable=SC2148,SC1090,SC1091
# If not running interactively, don't do anything
[[ "${-}" == *i* ]] || return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

shopt -s histappend         # Append to the history file, don't overwrite it
shopt -s histverify         #
shopt -s histreedit         # Allow reedit failed commands from history
shopt -s failglob           # Show not matching from glob as error
shopt -s autocd             # Automatic cd to folder if it's not a command and folder exists
shopt -s cdspell            # Try to correct dirnames when using cd
shopt -s dirspell           # Use dirnames to autocomplete
shopt -s dotglob            # Glob dotfile (hidden files) (globskipdots does the opposite)
shopt -s extglob            # Enable extended globing (paterns)
shopt -s globstar           # Enable '**' to glob recursively
shopt -s patsub_replacement # Enable '&' to represent the matching string in ${var//pattern/replace}

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

# shellcheck disable=SC1090
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).

if ! shopt -oq posix; then
  [ -f "${PREFIX}/share/bash-completion/bash_completion" ] &&
    source "${PREFIX}/share/bash-completion/bash_completion"
  [ -f "/usr/share/bash-completion/bash_completion" ] &&
    source "/usr/share/bash-completion/bash_completion"
  [ -f "${PREFIX}/etc/bash_completion" ] &&
    source "${PREFIX}/etc/bash_completion"
  [ -f "/etc/bash_completion" ] &&
    source "/etc/bash_completion"
fi

PS1='[\u@\h \W]\$ '

# In case of rustup
[ -f ~/.cargo/env ] && source ~/.cargo/env
# Add cd helper
[ -f ~/.config/bash/goto.sh ] && source ~/.config/bash/goto.sh
# Change prompt
[ -f ~/.config/bash/mirkop.sh ] && source ~/.config/bash/mirkop.sh
# Load util functions
[ -f ~/.config/bash/functions.sh ] && source ~/.config/bash/functions.sh

alias gt='goto'
alias git='git --no-pager'

if ! clear &> /dev/null; then
  [[ "${TERM}" == 'xterm'* ]] && bind -x '"\C-l": printf '\''\x1b[0H\x1b[3J'\'
else
  bind -x '"\C-l": clear'
fi
bind -x '"\C-o": __fzf_nvim_open_file'
bind -x '"\C-u": __fzf_cat_file'

# if not login shell ignore the rest
! shopt -q login_shell && return

# Add user paths to PATH
while read -r line; do
  [[ "${line}" == "#"* ]] && continue
  if [ -n "${line}" ]; then
    line=$(realpath "${line}")
    if [[ "${line}" == '@prepend '* ]]; then
      : "${line:9}"
      export PATH="${PATH}:${_%"${_##*[![:space:]\n]}"}"
    else
      export PATH="${PATH}:${line}"
    fi
  fi
done < ~/.config/.paths
unset -v line


source ~/.config/bash/lib/yq.sh
# Use .dotf.yaml to set environment variables
for key in $(yq.sh .shenv ~/.config/dotf/props.yaml); do
  value="$(yq.sh ".shenv.${key}" ~/.config/dotf/props.yaml)"
  if [[ "${value}" == "$ "* ]]; then
    export "${key}=$(eval "${value:2}")"
  else
    export "${key}=${value}"
  fi
done
unset -v key value
unset -f yq.sh
