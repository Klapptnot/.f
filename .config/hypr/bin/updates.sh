#! /bin/env bash

function main {
  if command -v yay &>/dev/null; then
    mapfile -t updates < <(yay -Qu | column -t | sed 's/^\([^ ]*\)/<b>\1<\/b>/g')
  elif command -v pacman &>/dev/null; then
    mapfile -t updates < <(pacman -Qu | column -t | sed 's/^\([^ ]*\)/<b>\1<\/b>/g')
  else
    [ "${1}" == 'show' ] && exit 1
    exit
  fi
  [ "${1}" == 'show' ] && exit

  local pslsa=""
  ((${#updates[@]} > 1)) && pslsa="(s)"

  printf -v lines '%s\\n' "${updates[@]}"
  printf '{"text": "%s Update%s", "tooltip":"%s"}' "${#updates[@]}" "${pslsa}" "${lines}"
}

main "${@}"
