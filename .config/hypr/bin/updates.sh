#! /bin/env bash

function main {
  if command -v yay &> /dev/null; then
    mapfile -t updates < <(yay -Qu | column -t | sed 's/^\([^ ]*\)/<b>\1<\/b>/g')
  elif command -v pacman &> /dev/null; then
    mapfile -t updates < <(pacman -Qu | column -t | sed 's/^\([^ ]*\)/<b>\1<\/b>/g')
  fi

  if [ "${1}" == 'show' ]; then
    ((${#updates[@]} > 0))
    exit ${?}
  fi

  local pslsa=""
  ((${#updates[@]} > 1)) && pslsa="(s)"

  printf -v lines '%s\\n' "${updates[@]}"
  printf '{"text": "%s Update%s", "tooltip":"%s"}' "${#updates[@]}" "${pslsa}" "${lines%%\\n}"
}

main "${@}"
