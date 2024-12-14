#!/usr/bin/bash

# Usage:
# ```bash
# spinner.start "Downloading network resources..." & # background process
# SPINNER_PID="${!}" # REQUIRED to save
# ... more commands
# spinner.stop "${SPINNER_PID}"
# ```
# NOTE: always make spinner.start a background process
# NOTE: always stop spinner accordingly (`trap <> SIGINT` as example)
function spinner.start {
  local _chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local _label="${1:-Loading...}"
  local i=0
  local n="${#_chars[@]}"
  read -r __rcol < <(od -An -N1 -tu1 /dev/urandom)
  printf '\x1b[?25l'
  while true; do
    printf "\x1b[0K%b\x1b[0G" "\x1b[38;5;${__rcol}m${_chars[i]}\x1b[00m ${_label}"
    ((i++))
    if ((i >= n)); then
      i=0
      read -r __rcol < <(od -An -N1 -tu1 /dev/urandom)
    fi
    sleep 0.008
  done
}
function spinner.stop {
  kill "${1:?Required to pass the spinner PID}" &> /dev/null
  sleep 0.006 # Perfect always clean line
  printf '\x1b[?25h\x1b[0G\x1b[0J'
}
