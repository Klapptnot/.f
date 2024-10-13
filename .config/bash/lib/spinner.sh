#!/usr/bin/env bash

function spinner.start {
  local _chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local _hint="${1:-Loading...}"
  local i=0
  local n="${#_chars[@]}"
  read -r _r_col < <(od -An -N1 -tu1 /dev/urandom)
  printf '\x1b[?25l'
  while true; do
    printf "\x1b[0K%b\x1b[0G" "\x1b[38;5;${_r_col//\ /}m${_chars[i]}\x1b[00m ${_hint}"
    ((i++))
    if ((i >= n)); then
      i=0
      read -r _r_col < <(od -An -N1 -tu1 /dev/urandom)
    fi
    sleep 0.008
  done
}
function spinner.stop {
  kill "${1}" &> /dev/null
  sleep 0.006 # Perfect always clean line
  printf '\x1b[?25h\x1b[0G\x1b[0J'
}
