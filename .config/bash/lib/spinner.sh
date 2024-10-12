#! /bin/env bash

function spinner.start {
  local __chars__=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local __hint__="${1:-Loading...}"
  local i=0
  local n="${#__chars__[@]}"
  local __rng__=''
  read -r __rng__ < <(od -An -N1 -tu1 /dev/urandom)
  printf '\x1b[?25l'
  while true; do
    printf "\x1b[0K%b\x1b[0G" "\x1b[38;5;${__rng__//\ /}m${__chars__[i]}\x1b[00m ${__hint__}"
    ((i++))
    if ((i >= n)); then
      i=0
      __rng__=$(od -An -N1 -tu1 /dev/urandom)
    fi
    sleep 0.008
  done
}
function spinner.stop {
  kill "${1}"
  sleep 0.006 # Perfect always clean line
  printf '\x1b[?25h\x1b[0G\x1b[0J'
}
