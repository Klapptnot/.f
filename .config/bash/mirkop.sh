#!/usr/bin/bash

# shellcheck disable=SC2120
function __mirkop_get_short_pwd {
  [ "${PWD}" == "${MIRKOP_LAST_PWD}" ] && printf '%b' "${MIRKOP_LAST_SPWD}" && return
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
  printf '%b' "${short_pwd_s}"
}

function __mirkop_cursor_position {
  # based on a script from http://invisible-island.net/xterm/xterm.faq.html
  exec < /dev/tty
  read -r oldstty < <(stty -g)
  stty raw -echo min 0
  printf "\033[6n" > /dev/tty
  IFS='[' read -d R -rs _ pos
  stty "${oldstty}"
  printf "%s" "${pos}"
}

function __mirkop_get_cwd_color {
  if [ "${MIRKOP_CONFIG[1]}" != 'true' ]; then
    printf '%s' "${MIRKOP_DIR_COLORS[5]}"
    return
  fi
  [ "${PWD}" == "${MIRKOP_LAST_PWD}" ] && printf '%s' "${MIRKOP_LAST_PWDC}" && return
  if command -v cksum &> /dev/null; then
    read -r s < <(pwd -P | cksum | cut -d' ' -f1 | printf '%-6x' "$(< /dev/stdin)" | tr ' ' '0' | head -c 6)
    local r=$((16#${s:0:2}))
    local g=$((16#${s:2:2}))
    local b=$((16#${s:4:2}))

    luminance=$((2126 * r + 7152 * g + 0722 * b))
    while ((luminance < 1200000)); do
      ((r = r < 255 ? r + 60 : 255))
      ((g = g < 255 ? g + 60 : 255))
      ((b = b < 255 ? b + 60 : 255))
      luminance=$((2126 * r + 7152 * g + 0722 * b))
    done
    ((r = r < 255 ? r : 255))
    ((g = g < 255 ? g : 255))
    ((b = b < 255 ? b : 255))

    printf '\\033[38;2;%d;%d;%dm' ${r} ${g} ${b}
  fi
}

function __mirkop_git_info {
  local git_branch=""

  if ! command -v git &> /dev/null || ! git rev-parse --is-inside-work-tree &> /dev/null; then
    printf '\n0\n'
    return
  fi

  read -r mod _ _ ins _ del _ < <(git diff --shortstat 2> /dev/null)
  read -r git_branch < <(git branch --show-current 2> /dev/null)
  mapfile -t untracked < <(git ls-files --other --exclude-standard 2> /dev/null)
  mapfile -t untracked_dirs < <(dirname -- "${untracked[@]}" 2> /dev/null | sort -u)

  # <files>@<branch> +<additions>/-<deletions> (● <untracked_files>@<untracked_folders>)
  printf '%b%d%b@%b%s%b %b+%d%b/%b-%d%b %b(● %d%b@%b%d%b)\033[0m\n' \
    "${MIRKOP_COLORS[9]}" "${mod}" "${MIRKOP_COLORS[10]}" \
    "${MIRKOP_COLORS[9]}" "${git_branch}" "${MIRKOP_COLORS[10]}" \
    "${MIRKOP_COLORS[7]}" "${ins}" "${MIRKOP_COLORS[10]}" \
    "${MIRKOP_COLORS[8]}" "${del}" "${MIRKOP_COLORS[10]}" \
    "${MIRKOP_COLORS[9]}" "${#untracked[@]}" "${MIRKOP_COLORS[10]}" \
    "${MIRKOP_COLORS[9]}" "${#untracked_dirs[@]}" "${MIRKOP_COLORS[10]}" 2> /dev/null

  : "${MIRKOP_COLORS[9]}${MIRKOP_COLORS[10]}${MIRKOP_COLORS[9]}"
  : "${_}${MIRKOP_COLORS[10]}${MIRKOP_COLORS[7]}${MIRKOP_COLORS[10]}"
  : "${_}${MIRKOP_COLORS[8]}${MIRKOP_COLORS[10]}${MIRKOP_COLORS[9]}"
  : "${_}${MIRKOP_COLORS[10]}${MIRKOP_COLORS[9]}${MIRKOP_COLORS[10]}\033[0m"
  : "${_@E}--"          # Somehow, it needs 2 characters to be right, so I added 2 dashes
  printf '%d\n' "${#_}" # Return the length of the color escape sequences
}

function __mirkop_generate_prompt_left {
  # Set the string for exit status indicator
  local last_exit_code="${1}"

  local -a prompt_parts=()

  read -r pwd_color < <(__mirkop_get_cwd_color)
  read -r short_cwd < <(__mirkop_get_short_pwd)

  prompt_parts+=(
    "\[${MIRKOP_COLORS[0]}\]${MIRKOP_STRINGS[0]}\[${MIRKOP_COLORS[3]}\]" # User
    "\[${MIRKOP_COLORS[1]}\]${MIRKOP_STRINGS[1]}\[${MIRKOP_COLORS[3]}\]" # From
    "\[${MIRKOP_COLORS[2]}\]${MIRKOP_STRINGS[2]}\[${MIRKOP_COLORS[3]}\]" # Host
    ":\[${pwd_color}\]${short_cwd}\[${MIRKOP_COLORS[3]}\]"               # CWD
    "${MIRKOP_STRINGS[3]} "                                              # Status and delim
  )
  printf -v prompt_string '%s' "${prompt_parts[@]}"

  PS1="${prompt_string}\[\033[0m\]"
}

function __mirkop_print_prompt_right {
  local -a rprompt_parts=()
  local comp=0

  {
    read -r git_info
    read -r color_length
  } < <(__mirkop_git_info)

  ((comp = comp + color_length))
  rprompt_parts+=("${git_info} ")

  jobs &> /dev/null # Prevent from printing finished jobs after command
  read -r num_jobs < <(jobs -r | wc -l)
  if ((num_jobs > 0)); then
    rprompt_parts+=("${MIRKOP_COLORS[6]}${num_jobs}  \033[0m ")
    : "${MIRKOP_COLORS[6]}\033[0m--"
    : "${_@E}"
    ((comp = comp + ${#_}))
  fi

  if ((${1} != 0)); then
    rprompt_parts+=("${MIRKOP_COLORS[4]}[${1}]\033[0m ")
    : "${MIRKOP_COLORS[4]}\033[0m"
    : "${_@E}"
    ((comp = comp + ${#_}))
  fi

  IFS=$'\n\t' read -r TIME_S < <(date "+${MIRKOP_CONFIG[2]}") && rprompt_parts+=("${TIME_S}")

  # Compensate the length of the right prompt
  # by adding the color escape sequences offset
  ((comp = COLUMNS + comp))

  printf -v rprompt_string "%b" "${rprompt_parts[@]}"
  printf "%${comp}s\x1b[0G" "${rprompt_string}"
}

function __mirkop_transient_prompt_left {
  read -r pwd_color < <(__mirkop_get_cwd_color)
  read -r short_cwd < <(__mirkop_get_short_pwd)
  read -r command < <(sed -E 's/\x1b/\\x1b/g;s/\r/\\r/g;s/\n/\\n/g') # read from stdin
  # ((${#command} > 128)) && command="${command:0:125}..."

  local _t=""
  [[ "${MIRKOP_CONFIG[3]}" == 'true' && -n "${command}" ]] && printf -v _t '\x1b]0;%s:%s %s\x07' "${short_cwd}" "${MIRKOP_STRINGS[3]}" "${command}"
  MIRKOP_SET_TITLE="${_t}"
  printf '\x1b7\x1b[%sH\x1b[0G\x1b[0K%b%s\x1b[0m:%s \x1b[38;5;14m%s\x1b[0m\x1b8' "${MIRKOP_LAST_POSITION}" "${pwd_color}" "${short_cwd}" "${MIRKOP_STRINGS[3]}" "${command}"
}

function __mirkop_generate_prompt {
  local last_exit_code="${?}"

  local oIFS="${IFS}"
  IFS=';' read -r row col < <(__mirkop_cursor_position 2> /dev/null)
  IFS="${oIFS}"

  # If the last command prints data with no trailing linefeed
  # add an indicator, and a linefeed
  ((col > 1)) && printf "\x1b[38;5;242m⏎\x1b[0m\n" && ((row++))

  __mirkop_generate_prompt_left "${last_exit_code}"
  __mirkop_print_prompt_right "${last_exit_code}"
  MIRKOP_LOADED_FULL=true
  MIRKOP_LAST_POSITION="${row};${col}"
}

function __mirkop_transient_prompt {
  [ "${MIRKOP_CONFIG[0]}" != 'true' ] && return

  # Overwrite the prompt cursor position, so it doesn't
  # randomly move around after `clear` command is issued
  [ "${LAST_COMMAND}" == 'clear' ] && {
    MIRKOP_LAST_POSITION='1;1'
    LAST_COMMAND_ITER=()
    return # Don't print the transient prompt
  }

  # If the prompt was printed in the last row
  # of the terminal, set the position to the row above
  # so that the transient prompt doesn't get overwritten
  if [ "${MIRKOP_LAST_POSITION}" == "${LINES};1" ]; then
    MIRKOP_LAST_POSITION="$((LINES - 1));1"
  fi

  [[ "${LAST_COMMAND}" == __* ]] && {
    ((MIRKOP_TRANSIENT_CMD == 0)) && __mirkop_transient_prompt_left "${MIRKOP_LAST_POSITION}" <<< ""
    LAST_COMMAND_ITER=()
    MIRKOP_TRANSIENT_CMD=0
    return # Don't increment the transient command counter
  }

  # MIRKOP_TRANSIENT_NOCMD=0
  ((MIRKOP_TRANSIENT_CMD++))

  LAST_COMMAND_ITER+=("${LAST_COMMAND}")

  local cmd_line_string=""
  local oIFS="${IFS}"
  IFS=';' cmd_line_string="${LAST_COMMAND_ITER[*]}"
  IFS="${oIFS}"

  __mirkop_transient_prompt_left "${MIRKOP_LAST_POSITION}" <<< "${cmd_line_string}"
}

function __mirkop_set_title {
  [ "${MIRKOP_CONFIG[3]}" != 'true' ] && MIRKOP_SET_TITLE=""
  printf '%b' "${MIRKOP_SET_TITLE}"
}

function __mirkop_reset_title {
  read -r cwd < <(__mirkop_get_short_pwd)
  printf '\x1b]0;%s\x07' "${cwd}"
}

function __mirkop_update_term_size {
  read -r LINES COLUMNS < <(stty size)
}

function __mirkop_pre_command_hook {
  [ "${MIRKOP_LOADED_FULL}" != 'true' ] && return
  # run pre-command hooks
  declare -g LAST_COMMAND="${BASH_COMMAND}"
  # declare -g LAST_COMMAND_STATUS=("${PIPESTATUS[@]}")
  for cmd in "${MIRKOP_PRECMD_HOOKS[@]}"; do ${cmd}; done
}

function __mirkop_post_command_hook {
  # run post-command hooks
  for cmd in "${MIRKOP_POSCMD_HOOKS[@]}"; do ${cmd}; done
}

#region Configuration
function __mirkop_load_prompt_config {
  # shellcheck disable=SC1090
  # It is hilarious that I have to source this
  # as yq command makes the script slower by 2 seconds
  # AND yq.sh SCRIPT IS A FOR-EACH-LINE LOOP
  source ~/.config/bash/lib/yq.sh || return 1
  function hex_to_shell {
    read -r s < /dev/stdin

    if [[ ${#s} -ne 7 || ${s:0:1} != "#" ]]; then
      printf '\\033[0m'
      return
    fi

    local r=$((16#${s:1:2}))
    local g=$((16#${s:3:2}))
    local b=$((16#${s:5:2}))

    printf '\\033[38;2;%d;%d;%dm' ${r} ${g} ${b}
  }

  # Enable CWD color based on the CWD string?
  IFS=$'\n\t' read -r do_rdircolor < <(yq.sh .rdircolor ~/.config/mirkop.yaml)
  # Transient prompt should be enabled?
  IFS=$'\n\t' read -r do_transient_p < <(yq.sh .transient ~/.config/mirkop.yaml)

  IFS=$'\n\t' read -r username < <(yq.sh .str.user ~/.config/mirkop.yaml)
  IFS=$'\n\t' read -r hostname < <(yq.sh .str.host ~/.config/mirkop.yaml)

  local from_str="base"
  [ -n "${SSH_TTY@A}" ] && from_str="sshd"
  IFS=$'\n\t' read -r from_str < <(yq.sh .str.from."${from_str}" ~/.config/mirkop.yaml)

  local delim="else"
  ((0 == $(id -u))) && delim="root"
  IFS=$'\n\t' read -r delim < <(yq.sh ".str.char.${delim}" ~/.config/mirkop.yaml)
  IFS=$'\n\t' read -r date_fmt < <(yq.sh .date_fmt ~/.config/mirkop.yaml)

  # MIRKOP_DIR_COLORS
  IFS=$'\n\t' read -r c_user < <(yq.sh .color.user.fg ~/.config/mirkop.yaml | hex_to_shell)   # [0]
  IFS=$'\n\t' read -r c_from < <(yq.sh .color.from.fg ~/.config/mirkop.yaml | hex_to_shell)   # [1]
  IFS=$'\n\t' read -r c_host < <(yq.sh .color.host.fg ~/.config/mirkop.yaml | hex_to_shell)   # [2]
  IFS=$'\n\t' read -r c_norm < <(yq.sh .color.normal.fg ~/.config/mirkop.yaml | hex_to_shell) # [3]
  IFS=$'\n\t' read -r c_error < <(yq.sh .color.error.fg ~/.config/mirkop.yaml | hex_to_shell) # [4]
  IFS=$'\n\t' read -r c_dir < <(yq.sh .color.dir.fg ~/.config/mirkop.yaml | hex_to_shell)     # [5]
  IFS=$'\n\t' read -r c_jobs < <(yq.sh .color.jobs.fg ~/.config/mirkop.yaml | hex_to_shell)   # [6]
  IFS=$'\n\t' read -r git_ins < <(yq.sh .color.git.i.fg ~/.config/mirkop.yaml | hex_to_shell) # [7]
  IFS=$'\n\t' read -r git_del < <(yq.sh .color.git.d.fg ~/.config/mirkop.yaml | hex_to_shell) # [8]
  IFS=$'\n\t' read -r git_any < <(yq.sh .color.git.a.fg ~/.config/mirkop.yaml | hex_to_shell) # [9]
  IFS=$'\n\t' read -r git_sep < <(yq.sh .color.git.s.fg ~/.config/mirkop.yaml | hex_to_shell) # [10]

  # shellcheck disable=SC2034
  declare -ga MIRKOP_CONFIG=(
    [0]="${do_transient_p}"
    [1]="${do_rdircolor}"
    [2]="${date_fmt}"
    [3]=true # Manage window title
  )

  # shellcheck disable=SC2034
  declare -ga MIRKOP_STRINGS=(
    [0]="${username}" # Username
    [1]="${from_str}" # From string
    [2]="${hostname}" # Hostname
    [3]="${delim}"    # Delimiter
  )

  # shellcheck disable=SC2034
  declare -ga MIRKOP_COLORS=(
    [0]="${c_user}"   # User color
    [1]="${c_from}"   # From color
    [2]="${c_host}"   # Host color
    [3]="${c_norm}"   # Normal color
    [4]="${c_error}"  # Error color
    [5]="${c_dir}"    # Directory color
    [6]="${c_jobs}"   # Jobs color
    [7]="${git_ins}"  # Git insertions color
    [8]="${git_del}"  # Git deletions color
    [9]="${git_any}"  # Git any changes color
    [10]="${git_sep}" # Git separator color
  )
  unset -f hex_to_shell
  unset -f yq.sh
  return 0
}
#endregion

function __mirkop_main {
  if __mirkop_load_prompt_config; then
    declare -g MIRKOP_LOADED_FULL=false
    declare -g MIRKOP_LAST_POSITION='0;0'
    declare -g MIRKOP_TRANSIENT_CMD=0
    declare -g MIRKOP_SET_TITLE=""
    declare -g MIRKOP_LAST_PWD=""
    declare -g MIRKOP_LAST_SPWD=""
    declare -g MIRKOP_LAST_PWDC=""
    # declare -g MIRKOP_TRANSIENT_NOCMD=0
    declare -ga LAST_COMMAND_ITER=()
    # declare -ga LAST_COMMAND_STATUS=()

    declare -ga MIRKOP_PRECMD_HOOKS=(
      '__mirkop_update_term_size'
      '__mirkop_transient_prompt'
      '__mirkop_set_title'
    )
    declare -ga MIRKOP_POSCMD_HOOKS=(
      '__mirkop_generate_prompt'
      '__mirkop_reset_title'
    )

    trap -- '__mirkop_pre_command_hook' DEBUG
    PROMPT_COMMAND='__mirkop_post_command_hook'
  fi
}

__mirkop_main
