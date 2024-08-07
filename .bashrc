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
      --preview='bat {}'
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

function print_path() {
  for p in ${PATH//:/\ }; do
    printf '%s\n' "${p}"
  done
}

# shellcheck disable=SC2120
function short_pwd {
  local short_pwd_s=""
  local old_pwd="${PWD}"
  if [[ "${PWD}" == "${HOME}"* ]]; then
    old_pwd="${PWD#*"${HOME}"}"
    short_pwd_s='~'
  fi
  for dir_item in ${old_pwd//\// }; do
    if [ "${dir_item}" == "${PWD##*/}" ]; then
      short_pwd_s+="/${dir_item}"
      break
    elif [ "${dir_item:0:1}" == "." ]; then
      short_pwd_s+="/${dir_item:0:2}"
      continue
    fi
    short_pwd_s+="/${dir_item:0:1}"
  done
  if [ "${1}" == '-e' ]; then
    export SPWD="${short_pwd_s}"
  else
    printf '%b' "${short_pwd_s}"
  fi
}

function curpos() {
  # based on a script from http://invisible-island.net/xterm/xterm.faq.html
  exec </dev/tty
  oldstty=$(stty -g)
  stty raw -echo min 0
  # on my system, the following line can be replaced by the line below it
  printf "\033[6n" >/dev/tty
  [ "${TERM}" == "xterm" ] && tput u7 >/dev/tty # when TERM=xterm (and relatives)
  IFS=';' read -r -d R -a pos
  stty "${oldstty}"
  row="${pos[0]:2}" # strip off the esc-[
  col="${pos[1]}"
  # change from one-based to zero based so they work with: tput cup $row $col
  printf "%s %s" "$((row - 1))" "$((col - 1))"
}

function prompt {
  # Set the string for exit status indicator
  local _s="${?}"

  local last_cmd_status=""
  (( "${_s}" > 0 )) && last_cmd_status="\033[38;05;01m[${_s}]\033[00m"
  # A fish-like pwd
  local short_cwd="$(short_pwd)"

  local delim="\u25ba"                  # ►
  ((0 == "$(id -u)")) && delim="\u26a1" # ⚡

  # Add a \n if needed
  IFS=' ' read -r cROW cCOL < <(curpos 2>/dev/null)
  local pPS1=""
  (("${cCOL}" != 0)) && pPS1="\033[38;5;242m⏎\033[0m\n"

  # jobs &>/dev/null
  # local NUM_JOBS=0
  # for job in $(jobs -p); do [[ $job ]] && ((NUM_JOBS++)); done
  # Update the prompt string
  pPS1+="\033[38;2;235;100;52mbash\033[00m\033[38;2;255;255;255m::\033[00m\033[38;2;155;92;237m\u\033[00m:\033[38;2;4;201;172m${short_cwd}\033[00m${last_cmd_status}${delim@E} "
  PS1="${pPS1}"
}

PROMPT_COMMAND='prompt'

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some bindings
bind -x '"\C-l": clear'
bind -x '"\C-o": fnvim'
bind -x '"\C-u": fgfc'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

# shellcheck disable=SC1090
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

[ -f "${HOME}/.cargo/env" ] && source "${HOME}/.cargo/env"
[ -f "${HOME}/.local/lib/shlib/goto.sh" ] && source "${HOME}/.local/lib/shlib/goto.sh"
alias gt='goto'

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
