#!/usr/bin/bash

function main {
  if command -v yay &> /dev/null; then
    mapfile -t upgradable_pkgs < <(yay -Qu | column -t | sed 's/^\([^ ]*\)/<b>\1<\/b>/g')
  elif command -v pacman &> /dev/null; then
    mapfile -t upgradable_pkgs < <(pacman -Qu | column -t | sed 's/^\([^ ]*\)/<b>\1<\/b>/g')
  fi

  local upgradables="${#upgradable_pkgs[@]}"

  case "${1}" in
    'should-show') exit $((upgradables > 0)) ;;
    'waybar-json') waybar_json "${upgradable_pkgs[@]}" ;;
    'do-upgrade') ((upgradables > 0)) && do_upgrade ;;
  esac

}

function waybar_json {
  local pslsa=""
  ((${#} > 1)) && pslsa="(s)"

  printf -v lines '%s\\n' "${@}"
  printf '{"text": "%s Update%s", "tooltip":"%s"}' "${#}" "${pslsa}" "${lines%%\\n}"
}

function do_upgrade {
  if kitty -e yay -Syyu; then
    notify-send 'The system has been updated'
  fi
}

main "${@}"
