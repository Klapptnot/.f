# shellcheck disable=SC2148
# If not running interactively, don't do anything
[[ "${-}" =~ 'i' ]] || return

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

function fzf_get_file {
  local file
  file=$(
    fzf --prompt 'File: ' --pointer '=>' --marker '==' \
      --preview-window '65%' --preview-label 'Preview' \
      --preview='bat --paging never --wrap character --number --color always --italic-text always --line-range :250 {}'
  )
  if ! [ -f "${file}" ]; then
    return 1
  fi
  printf '%s' "${file}"
}

function fnvim {
  local file
  if file=$(fzf_get_file); then
    nvim "${file}"
  fi
}

function fgfc {
  local file
  if file=$(fzf_get_file); then
    gfc "${file}" "${@}"
  fi
}

# shellcheck disable=SC2120
function short_pwd {
  local DWP ODWP="${PWD}"
  if [[ "${PWD}" == "${HOME}"* ]]; then
    ODWP="${PWD#*"${HOME}"}"
    DWP='~'
  fi
  for dir_item in ${ODWP//\// }; do
    if [ "${dir_item}" == "${PWD##*/}" ]; then
      DWP+="/${dir_item}"
      break
    elif [ "${dir_item:0:1}" == "." ]; then
      DWP+="/${dir_item:0:2}"
      continue
    fi
    DWP+="/${dir_item:0:1}"
  done
  if [ "${1}" == '-e' ]; then
    export SPWD="${DWP}"
  else
    printf '%b' "${DWP}"
  fi
}

function curpos() {
  # based on a script from http://invisible-island.net/xterm/xterm.faq.html
  exec </dev/tty
  oldstty=$(stty -g)
  stty raw -echo min 0
  # on my system, the following line can be replaced by the line below it
  echo -en "\033[6n" >/dev/tty
  # tput u7 > /dev/tty    # when TERM=xterm (and relatives)
  IFS=';' read -r -d R -a pos
  stty "${oldstty}"
  row="${pos[0]:2}" # strip off the esc-[
  col="${pos[1]}"
  # change from one-based to zero based so they work with: tput cup $row $col
  printf "%s:%s" "$((row - 1))" "$((col - 1))"
}

function update_prompt {
  # Set the string for exit status indicator
  local _s="${?}"
  # Early return when no update needed
  [ "${BPUI}" == "${PWD}:${_s}" ] && return
  # local STATUS_INDC="\[\033[01;32m\]\[\342\234\223\]\[\033[00m\]"
  local STATUS_INDC=""
  [ "${_s}" -gt 0 ] && STATUS_INDC="\033[38;05;01m[${_s}]\033[00m"
  # Set a fish-like pwd
  # shellcheck disable=SC2155
  local SPWD="$(short_pwd)"
  # Set custom delimeters
  local DELIM="\u25ba"                 # ►
  [ 0 -eq "$(id -u)" ] && DELIM="\u26a1" # ⚡
  # Get cursor pos and add a \n if needed
  # shellcheck disable=SC2155
  local CURSOR_POS="$(curpos 2>/dev/null)"
  # local cROW="${CURSOR_POS%:*}"
  local cCOL="${CURSOR_POS#*:}"

  local PSP=""
  # Add a new line before prompt if process does not add one
  [ "${cCOL}" != 0 ] && PSP=$"\n"

  jobs &>/dev/null
  local NUM_JOBS=0
  for job in $(jobs -p); do [[ $job ]] && ((NUM_JOBS++)); done
  # Update the prompt string
  PS1=$"${PSP}\033[0J\033[0K\033[38;2;235;100;52mbash\033[00m\033[38;2;255;255;255m as \033[00m\033[38;2;155;92;237mklapptnot\033[00m:\033[38;2;4;201;172m${SPWD}\033[00m${STATUS_INDC}${DELIM@E} "
  # Save a string with info
  BPUI="${PWD}:${_s}"
}

PROMPT_COMMAND='update_prompt'

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some bindings
bind -x '"\C-l": clear'
bind -x '"\C-o": fnvim'
bind -x '"\C-u": fgfc'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='termux-notification -t "$([ ${?} == 0 ] && echo Terminal: succeded || echo Terminal: error)" -c  "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

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
  # shellcheck disable=SC1090,SC1091
  if [ -f "${PREFIX}/share/bash-completion/bash_completion" ]; then
    source "${PREFIX}/share/bash-completion/bash_completion"
  elif [ -f "${PREFIX}/etc/bash_completion" ]; then
    source "${PREFIX}/etc/bash_completion"
  fi
fi

# shellcheck disable=SC1091
[ -f "${UTILS}/lib/goto.sh" ] && source "${UTILS}/lib/goto.sh"

function unc() {
  [ -d ~/.config/nvim ] && rm -rf ~/.config/nvim/*
  # git clone "https://github.com/Klapptnot/spruce.git" ~/.config/nvim/
  git clone ~/repos/spruce/ ~/.config/nvim/
}
function print_path() {
  for p in ${PATH//:/\ }; do
    printf '%s\n' "${p}"
  done
}
alias apt-fu='apt update; apt upgrade -y; apt update'
alias gt='goto'
