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

function __mirkop_load_prompt_config {
  function hex_to_shell {
    read -r s < /dev/stdin

    local r=$((16#${s:1:2}))
    local g=$((16#${s:3:2}))
    local b=$((16#${s:5:2}))

    printf '\\033[38;2;%d;%d;%dm' ${r} ${g} ${b}
  }

  IFS=$'\n\t' read -r username < <(yq.sh .str.user ~/.config/mirkop.yaml)
  IFS=$'\n\t' read -r hostname < <(yq.sh .str.host ~/.config/mirkop.yaml)

  local from_str="base"
  [ -n "${SSH_TTY@A}" ] && from_str="sshd"
  IFS=$'\n\t' read -r from_str < <(yq.sh .str.from."${from_str}" ~/.config/mirkop.yaml)

  local delim="else"
  ((0 == $(id -u))) && delim="root"
  IFS=$'\n\t' read -r delim < <(yq.sh ".str.char.${delim}" ~/.config/mirkop.yaml)

  IFS=$'\n\t' read -r c_user < <(yq.sh .color.user.fg ~/.config/mirkop.yaml | hex_to_shell)
  IFS=$'\n\t' read -r c_host < <(yq.sh .color.host.fg ~/.config/mirkop.yaml | hex_to_shell)
  IFS=$'\n\t' read -r c_from < <(yq.sh .color.from.fg ~/.config/mirkop.yaml | hex_to_shell)
  IFS=$'\n\t' read -r c_norm < <(yq.sh .color.normal.fg ~/.config/mirkop.yaml | hex_to_shell)

  IFS=$'\n\t' read -r c_error < <(yq.sh .color.error.fg ~/.config/mirkop.yaml | hex_to_shell)

  # shellcheck disable=SC2034
  declare -g MIRKOP_PROMPT_STR=(
    "${username}"
    "${from_str}"
    "${hostname}"
    "${delim}"
  )

  # shellcheck disable=SC2034
  declare -g MIRKOP_PROMPT_COLORS=(
    "${c_user}"
    "${c_from}"
    "${c_host}"
    "${c_norm}"
    "${c_error}"
  )
}

function __mirkop_print_prompt_right {
  local rprompt_parts=()
  local comp=0

  jobs &> /dev/null # Prevent from printing finished jobs after command
  read -r num_jobs < <(jobs -r | wc -l)

  if ((num_jobs > 1)); then
    rprompt_parts+=("${num_jobs} jobs ")
  elif ((num_jobs > 0)); then
    rprompt_parts+=("${num_jobs} job ")
  fi

  if ((${1} != 0)); then
    rprompt_parts+=("${MIRKOP_PROMPT_COLORS[4]}[${1}]\x1b[0m ")
    : "${MIRKOP_PROMPT_COLORS[4]}\033[0m"
    : "${_@E}"
    ((comp = comp + ${#_}))
  fi

  IFS=$'\n\t' read -r TIME_S < <(date +'%x %X') && rprompt_parts+=("${TIME_S}")

  printf -v rprompt_string "%b" "${rprompt_parts[@]}"
  printf "%$((COLUMNS + comp))s\x1b[0G" "${rprompt_string}"
}

function __mirkop_generate_prompt_left {
  # Set the string for exit status indicator
  local last_exit_code="${?}"

  IFS=';' read -r _ col < <(__mirkop_cursor_position 2> /dev/null)
  ((col > 1)) && printf "\x1b[38;5;242m⏎\x1b[0m\n"

  local prompt_parts=()

  read -r pwd_color < <(__mirkop_get_cwd_color)
  read -r short_cwd < <(__mirkop_get_short_pwd)

  prompt_parts+=(
    "\[${MIRKOP_PROMPT_COLORS[0]}\]${MIRKOP_PROMPT_STR[0]}\[${MIRKOP_PROMPT_COLORS[3]}\]" # User
    "\[${MIRKOP_PROMPT_COLORS[1]}\]${MIRKOP_PROMPT_STR[1]}\[${MIRKOP_PROMPT_COLORS[3]}\]" # From
    "\[${MIRKOP_PROMPT_COLORS[2]}\]${MIRKOP_PROMPT_STR[2]}\[${MIRKOP_PROMPT_COLORS[3]}\]" # Host
    ":\[${pwd_color}\]${short_cwd}\[${MIRKOP_PROMPT_COLORS[3]}\]"                         # CWD
    "${MIRKOP_PROMPT_STR[3]} "                                                            # Status and delim
  )
  printf -v prompt_string '%s' "${prompt_parts[@]}"

  __mirkop_print_prompt_right "${last_exit_code}"
  PS1="${prompt_string}\[\033[0m\]"
}

# shellcheck disable=SC1090
source ~/.config/bash/lib/yq.sh
__mirkop_load_prompt_config && PROMPT_COMMAND='__mirkop_generate_prompt_left'
unset -f yq.sh
