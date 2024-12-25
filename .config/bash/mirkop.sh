#!/usr/bin/bash

# shellcheck disable=SC2120
function __mirkop_get_short_pwd {
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
  oldstty=$(stty -g)
  stty raw -echo min 0
  # on my system, the following line can be replaced by the line below it
  printf "\033[6n" > /dev/tty
  [ "${TERM}" == "xterm" ] && tput u7 > /dev/tty # when TERM=xterm (and relatives)
  IFS=';' read -r -d R -a pos
  stty "${oldstty}"
  row="${pos[0]:2}" # strip off the ESC[
  col="${pos[1]}"
  printf "%s;%s" "${row}" "${col}"
}

function __mirkop_get_cwd_color {
  if [ "${MIRKOP_CONFIG[1]}" != 'true' ]; then
    printf '%s' "${MIRKOP_DIR_COLORS[5]}"
    return
  fi
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

  read -r mods _ _ inss _ dels _ < <(git diff --shortstat 2> /dev/null)
  read -r git_branch < <(git branch --show-current 2> /dev/null)
  mapfile -t untracked < <(git ls-files --other --exclude-standard 2> /dev/null)
  mapfile -t untracked_dirs < <(dirname -- "${untracked[@]}" 2> /dev/null | sort -u)

  # <files>@<branch> +<additions>/-<deletions> (● <untracked_files>@<untracked_folders>)
  printf '%b%d%b@%b%s%b %b+%d%b/%b-%d%b %b(● %d%b@%b%d%b)\033[0m\n' \
    "${MIRKOP_COLORS[8]}" "${mods}" "${MIRKOP_COLORS[9]}" \
    "${MIRKOP_COLORS[8]}" "${git_branch}" "${MIRKOP_COLORS[9]}" \
    "${MIRKOP_COLORS[6]}" "${inss}" "${MIRKOP_COLORS[9]}" \
    "${MIRKOP_COLORS[7]}" "${dels}" "${MIRKOP_COLORS[9]}" \
    "${MIRKOP_COLORS[8]}" "${#untracked[@]}" "${MIRKOP_COLORS[9]}" \
    "${MIRKOP_COLORS[8]}" "${#untracked_dirs[@]}" "${MIRKOP_COLORS[9]}"

  : "${MIRKOP_COLORS[8]}${MIRKOP_COLORS[9]}${MIRKOP_COLORS[8]}"
  : "${_}${MIRKOP_COLORS[9]}${MIRKOP_COLORS[6]}${MIRKOP_COLORS[9]}"
  : "${_}${MIRKOP_COLORS[7]}${MIRKOP_COLORS[9]}${MIRKOP_COLORS[8]}"
  : "${_}${MIRKOP_COLORS[9]}${MIRKOP_COLORS[8]}${MIRKOP_COLORS[9]}\033[0m"
  : "${_@E}--"          # Somehow, it needs 2 characters to be right, so I added 2 dashes
  printf '%d\n' "${#_}" # Return the length of the color escape sequences
}

function __mirkop_generate_prompt_left {
  # Set the string for exit status indicator
  local last_exit_code="${1}"

  IFS=';' read -r _ col < <(__mirkop_cursor_position 2> /dev/null)
  ((col > 1)) && printf "\x1b[38;5;242m⏎\x1b[0m\n"

  local prompt_parts=()

  read -r pwd_color < <(__mirkop_get_cwd_color)
  read -r short_cwd < <(__mirkop_get_short_pwd)

  prompt_parts+=(
    "\[${MIRKOP_COLORS[0]}\]${MIRKOP_STRINGS[0]}\[${MIRKOP_COLORS[3]}\]" # User
    "\[${MIRKOP_COLORS[1]}\]${MIRKOP_STRINGS[1]}\[${MIRKOP_COLORS[3]}\]" # From
    "\[${MIRKOP_COLORS[2]}\]${MIRKOP_STRINGS[2]}\[${MIRKOP_COLORS[3]}\]" # Host
    ":\[${pwd_color}\]${short_cwd}\[${MIRKOP_COLORS[3]}\]"                         # CWD
    "${MIRKOP_STRINGS[3]} "                                                            # Status and delim
  )
  printf -v prompt_string '%s' "${prompt_parts[@]}"

  PS1="${prompt_string}\[\033[0m\]"
}

function __mirkop_print_prompt_right {
  local rprompt_parts=()
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
    rprompt_parts+=("${MIRKOP_COLORS[9]}${num_jobs}  \033[0m ")
    : "${MIRKOP_COLORS[9]}\033[0m--"
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
  local LAST_COMMAND="${1}"
  read -r pwd_color < <(__mirkop_get_cwd_color)
  read -r short_cwd < <(__mirkop_get_short_pwd)
  read -r command < <(sed -E 's/\x1b/\\x1b/g' <<< "${LAST_COMMAND}")
  ((${#command} > 150)) && command="${command:0:147}..."

  printf '\x1b[1A\x1b[0G\x1b[0K%b%s\x1b[0m:%s \x1b[38;5;14m%s\x1b[0m\n' "${pwd_color}" "${short_cwd}" "${MIRKOP_STRINGS[3]}" "${command}"
}

function __mirkop_transient_prompt {
  local LAST_COMMAND="${1}"
  if [ "${MIRKOP_CONFIG[0]}" == 'true' ] && ${MIRKOP_LOADED_FULL}; then
    __mirkop_transient_prompt_left "${LAST_COMMAND}"
  fi
}

function __mirkop_generate_prompt {
  local last_exit_code="${?}"
  __mirkop_generate_prompt_left "${last_exit_code}"
  if [ "${OBASH_COMMAND}" != '__mirkop_generate_prompt' ]; then
    __mirkop_transient_prompt "${LAST_COMMAND:-ls -la # history empty}"
  fi
  __mirkop_print_prompt_right "${last_exit_code}"
  ${MIRKOP_LOADED_FULL} || read -r LAST_COMMAND < <(fc -ln -1)
  MIRKOP_LOADED_FULL=true
}

function __mirkop_pre_command_hook {
  OBASH_COMMAND+="${BASH_COMMAND}"
  if [ "${BASH_COMMAND}" != __mirkop_generate_prompt ]; then
    LAST_COMMAND="${BASH_COMMAND}"
    [ "${BASH_COMMAND}" != 'clear' ] && OBASH_COMMAND=""
    __mirkop_transient_prompt "${BASH_COMMAND:-ls -la # history empty}"
  fi
}

function __mirkop_load_prompt_config {
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
  IFS=$'\n\t' read -r git_ins < <(yq.sh .color.git.i.fg ~/.config/mirkop.yaml | hex_to_shell) # [6]
  IFS=$'\n\t' read -r git_del < <(yq.sh .color.git.d.fg ~/.config/mirkop.yaml | hex_to_shell) # [7]
  IFS=$'\n\t' read -r git_any < <(yq.sh .color.git.a.fg ~/.config/mirkop.yaml | hex_to_shell) # [8]
  IFS=$'\n\t' read -r git_sep < <(yq.sh .color.git.s.fg ~/.config/mirkop.yaml | hex_to_shell) # [9]
  IFS=$'\n\t' read -r c_jobs < <(yq.sh .color.jobs.fg ~/.config/mirkop.yaml | hex_to_shell)   # [10]

  # shellcheck disable=SC2034
  declare -ga MIRKOP_CONFIG=(
    [0]="${do_transient_p}"
    [1]="${do_rdircolor}"
    [2]="${date_fmt}"
  )

  # shellcheck disable=SC2034
  declare -g MIRKOP_STRINGS=(
    [0]="${username}" # Username
    [1]="${from_str}" # From string
    [2]="${hostname}" # Hostname
    [3]="${delim}"    # Delimiter
    [4]="${date_fmt}" # Date format string
  )

  # shellcheck disable=SC2034
  declare -g MIRKOP_COLORS=(
    [0]="${c_user}"  # User color
    [1]="${c_from}"  # From color
    [2]="${c_host}"  # Host color
    [3]="${c_norm}"  # Normal color
    [4]="${c_error}" # Error color
    [5]="${c_dir}"   # Directory color
    [6]="${git_ins}" # Git insertions color
    [7]="${git_del}" # Git deletions color
    [8]="${git_any}" # Git any changes color
    [9]="${git_sep}" # Git separator color
    [10]="${c_jobs}" # Jobs color
  )
}

# shellcheck disable=SC1090
source ~/.config/bash/lib/yq.sh
__mirkop_load_prompt_config && {
  MIRKOP_LOADED_FULL=false
  trap -- '__mirkop_pre_command_hook' DEBUG
  PROMPT_COMMAND='__mirkop_generate_prompt'
}
unset -f yq.sh
