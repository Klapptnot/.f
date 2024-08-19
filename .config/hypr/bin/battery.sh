#! /bin/env bash

function main() {
  local format_it='\{\{([a-z_]+)\}\}'
  local what="${1:-"{{icon}} {{capacity}}% {{status}}"}"

  while [[ "${what}" =~ ${format_it} ]]; do
    IFS=$'\n' read -r res < <(battery-data-get "${BASH_REMATCH[1]}")
    what="${what//"${BASH_REMATCH[0]}"/"${res}"}"
  done

  printf '%s\n' "${what}"
}

function battery-data-get() {
  local key="${1}"
  case "${key}" in
    'capacity')
      read -r capacity < /sys/class/power_supply/BAT*/capacity
      printf '%3d' "${capacity}"
      ;;
    'status')
      cat /sys/class/power_supply/BAT*/status
      ;;
    'icon')
      read -r status </sys/class/power_supply/BAT*/status
      [ "${status}" == "Charging" ] && printf '' && return
      read -r charge </sys/class/power_supply/BAT*/capacity
      (( charge > 90 )) && printf '󰁹' && return
      (( charge > 80 )) && printf '󰂂' && return
      (( charge > 70 )) && printf '󰂁' && return
      (( charge > 60 )) && printf '󰂀' && return
      (( charge > 50 )) && printf '󰁿' && return
      (( charge > 40 )) && printf '󰁾' && return
      (( charge > 30 )) && printf '󰁽' && return
      (( charge > 20 )) && printf '󰁼' && return
      (( charge > 10 )) && printf '󰁻' && return
      (( charge > 00 )) && printf '󰁺' && return
      ;;
    'name')
      cat /sys/class/power_supply/BAT*/model_name
      ;;
    *)
      printf 'Unknown key: %s\n' "${key}" >&2
      exit 1
      ;;
  esac
}

main "${@}"
