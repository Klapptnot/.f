# shellcheck disable=SC2148,SC1090,SC1091,SC2120
# If not running interactively, don't do anything
[[ "${-}" != *i* ]] && return

# See bash(1) for more options
HISTCONTROL=ignoreboth:erasedups                                                     # Remove duplicates in history, ignore commands starting with space
HISTIGNORE='&:ls:[bf]g:exit:history:cd:cd -:cd ..:cd ~:pwd:rm *:sudo rm*:git clone*' # Ignore these commands in history
HISTTIMEFORMAT='%F %T'                                                               # Add timestamp to history entries
HISTSIZE=1000                                                                        # Number of commands to keep in history
HISTFILESIZE=2000                                                                    # Number of lines to keep in history file

shopt -s histappend         # Add new history entries by appending to history file
shopt -s histverify         # When using Ctrl+R, allow editing command before execution
shopt -s histreedit         # Allow editing of failed commands in history
shopt -s failglob           # Report error when glob patterns don't match any files
shopt -s autocd             # Change directory automatically if command name matches directory
shopt -s cdspell            # Auto-correct minor spelling errors in cd commands
shopt -s dirspell           # Enable spelling correction during directory name completion
shopt -s dotglob            # Include hidden files (dotfiles) in pathname expansion
shopt -s extglob            # Enable extended pattern matching operators
shopt -s globstar           # Enable ** for recursive directory matching
shopt -s patsub_replacement # Enable & to reference matched text in pattern substitution

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

PS1='[\u@\h \W]\$ '

# Define array of source files with comments
BASHRC_SOURCED=(
  "${HOME}/.cargo/env"                         # In case of rustup
  "${HOME}/.bash_aliases"                      # Load aliases
  "${HOME}/.config/bash/goto.sh"               # Add cd helper
  "${HOME}/.config/bash/mirkop.sh"             # Change prompt
  "${HOME}/.config/bash/functions.sh"          # Load util functions
  "${HOME}/.config/bash/carapace.sh"           # Load carapace completion
  # "/usr/share/bash-completion/bash_completion" # Load bash completion
)

# Source each file if it exists
for file in "${BASHRC_SOURCED[@]}"; do
  if [ -f "${file}" ]; then
    if ! source "${file}" &> /dev/null; then
      printf '~''/.bashrc:%s Failed to source %s\n' "${LINENO}" "${file}" >&2
    fi
  fi
done

alias gt='goto'
alias git='git --no-pager'
alias ls='ls --color=yes'

if ! clear &> /dev/null; then
  # The sequence is ESC [ H ESC [ 2 J with -x
  # ESC [ 0 H ESC [ 3 J to clear scrollback buffer
  function clear {
    if [[ "${*}" = '-'*'x'* ]]; then
      printf '\x1b[0H\x1b[2J'
      return
    fi
    printf '\x1b[0H\x1b[3J'
  }
fi

bind -x '"\C-l": clear'
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
for key in $(yq.sh .shell_env ~/.config/dotf/props.yaml); do
  value="$(yq.sh ".shell_env.${key}" ~/.config/dotf/props.yaml)"
  if [[ "${value}" == "$ "* ]]; then
    export "${key}=$(eval "${value:2}")"
  else
    export "${key}=${value}"
  fi
done
unset -v key value
unset -f yq.sh
