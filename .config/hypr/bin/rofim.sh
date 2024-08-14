#!/bin/env bash
# |>----|>----|>----|><-><|----<|----<|----<|
# |>    from Klapptnot's Hyprland setup    <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# shellcheck disable=SC1090,2155

# Rofi hides everything that comes after a `\r` char.
# Interesting... it's our duty as Minecraft players
# to abuse this mechanic.

source ~/.local/lib/bash/strtoys.sh
source ~/.local/lib/bash/rsum.sh
source ~/.local/lib/bash/logger.sh

function o+e_handler {
  "${@}" 2> "${epPipe}" | {
    local o="$(cat)"
    test -n "${o}" && log i "${o}"
  } &
  read -ra err < "${epPipe}"
  test -n "${err[*]}" && {
    log e "${err[*]}"
  }
}

function rofi-wifi-menu-populate {
  mapfile BSSIDs_F < <(nmcli --fields BSSID device wifi list)
  mapfile SSIDs_F < <(nmcli --fields SSID device wifi list)
  mapfile SECURITYs_F < <(nmcli --fields SECURITY device wifi list)
  mapfile BARSs_P < <(nmcli --fields BARS device wifi list)
  mapfile DEVICEs_P < <(nmcli --fields DEVICE device wifi list)
  mapfile ACTIVEs_P < <(nmcli --fields ACTIVE device wifi list)

  for ((i = 1; i < ${#ACTIVEs_P[@]}; i++)); do
    [[ "$(str.strip "${ACTIVEs_P[i]}")" == 'yes' ]] && {
      active_wifi="${i}"
      break
    }
  done
  unset IN_USEs_P
  log d "{ ${active_wifi@A} }"

  local rofi_menu_str=""
  local rofi_menu_str_alt=""
  local rofi_menu_alt=()
  for ((i = 1; i < ${#SSIDs_F[@]}; i++)); do
    SSIDs_F[i]="$(str.strip "${SSIDs_F[i]}")"
    BSSIDs_F[i]="$(str.strip "${BSSIDs_F[i]}")"
    SECURITYs_F[i]="$(str.strip "${SECURITYs_F[i]}")"
    BARSs_P[i]="$(str.strip "${BARSs_P[i]}")"
    DEVICEs_P[i]="$(str.strip "${DEVICEs_P[i]}")"
    test "${active_wifi}" == "${i}" && DEVICEs_P[i]="${DEVICEs_P[i]} ***"
    printf -v rofi_menu_str '  %-16s  %s  %s  %s\rconnect_to %d' "${SSIDs_F[i]}" \
      "${SECURITYs_F[i]}" \
      "${BARSs_P[i]}" \
      "${DEVICEs_P[i]}" "${i}"
    printf -v rofi_menu_str_alt '  %-16s  %s  %s  %s\rconnect_to_ask %d' "${SSIDs_F[i]}" \
      "${SECURITYs_F[i]}" \
      "${BARSs_P[i]}" \
      "${DEVICEs_P[i]}" "${i}"
    rofi_menu+=("${rofi_menu_str}")
    rofi_menu_alt+=("${rofi_menu_str_alt}")
  done

  test "${active_wifi}" != 'null' && log d "{ active_connection=${SSIDs_F[active_wifi]@Q} }"

  rofi_menu=(
    $'Connect to\rtitle_line'
    "${rofi_menu[@]}"
    "${separator_line}"
    $'Connect to (asks password)\rtitle_line'
    "${rofi_menu_alt[@]}"
    "${separator_line}"
  )
}

function rofi-wifi-menu-do {
  local opPipe="/tmp/rwmdo_$(rsum)"
  local epPipe="/tmp/rwmde_$(rsum)"
  mkfifo "${opPipe}"
  mkfifo "${epPipe}"

  local wifi_enabled=false
  local active_wifi=null
  test "$(nmcli --get-value WIFI general)" == 'enabled' && wifi_enabled=true
  log d "{ ${wifi_enabled@A} }"

  local toggle_menu_text=$'Enable WiFi\renable_wifi'
  ${wifi_enabled} && toggle_menu_text=$'Disable WiFi\rdisable_wifi'

  local separator_line=$'\rseparator_line'

  local rofi_menu=()

  ${wifi_enabled} && rofi-wifi-menu-populate

  test ${active_wifi} != 'null' && rofi_menu+=(
    $'Disconnect from WiFi\rdisconnect_active '"${active_wifi}"
  )

  rofi_menu+=(
    "${toggle_menu_text}"
    $'Cancel\rcancel_all'
  )

  local rofi_menu_str=""
  IFS=$'\n' rofi_menu_str="${rofi_menu[*]}"
  rofi -dmenu <<< "${rofi_menu_str}" | sed 's/.*\r\(.*\)/\1/' > "${opPipe}" &

  IFS=$' \n' read -r operation arg1 < "${opPipe}"
  log d "{ ${operation@A}, ${arg1@A} }"

  case "${operation}" in
    'connect_to')
      test "${active_wifi}" == "${arg1}" && {
        log e "already connected to '${SSIDs_F[arg1]}'"
        rm "${opPipe}" "${epPipe}" &>/dev/null
        return
      }
      log i "connect to ${SSIDs_F[arg1]}"
      o+e_handler nmcli device wifi connect "${BSSIDs_F[arg1]}"
      rm "${opPipe}" "${epPipe}" &>/dev/null
      return 1
      ;;
    'connect_to_ask')
      test "${active_wifi}" == "${arg1}" && {
        log e "already connected to '${SSIDs_F[arg1]}'"
        return
      }
      rofi -dmenu -mesg "Type '${SSIDs_F[arg1]}' password" \
        -theme ~/.config/rofi/sinput.rasi \
        -theme-str 'entry { placeholder: " password"; }' > "${opPipe}" &
      read -r password < "${opPipe}"
      test -z "${password}" && {
        log e "No password has been received"
        rm "${opPipe}" "${epPipe}" &>/dev/null
        return
      }
      log i "connect to ${SSIDs_F[arg1]}"
      o+e_handler nmcli device wifi connect "${BSSIDs_F[arg1]}" password "${password}"
      rm "${opPipe}" "${epPipe}" &>/dev/null
      return 1
      ;;
    'cancel_all')
      log i 'Operation cancelled, exiting'
      rm "${opPipe}" "${epPipe}" &>/dev/null
      return 1 # do not redraw menu
      ;;
    'disconnect_active')
      log i 'disconneting from WiFi'
      o+e_handler nmcli connection down id "${SSIDs_F[arg1]}"
      ;;
    'enable_wifi')
      log i "toggle WiFi on"
      o+e_handler nmcli radio wifi on
      ;;
    'disable_wifi')
      log i "toggle WiFi off"
      o+e_handler nmcli radio wifi off
      ;;
    *)
      log e 'No valid operation was selected'
      return 1
      ;;
  esac
  rm "${opPipe}" "${epPipe}" &>/dev/null
  return 0
}

function main {
  local mode="${1:?A mode is needed: \{runner, clipboard, emoji, wifi, bluetooth\}}"
  shift 1

  command -v rofi &> /dev/null || {
    log e "Rofi not installed or not in PATH" >&2
    exit
  }

  function no_tlf {
    printf '%s' "${2:0:(${#2} - 1)}"
  }

  killall rofi &> /dev/null
  case "${mode}" in
    runner)
      rofi -show drun -theme ~/.config/rofi/drun.rasi
      ;;
    clipboard)
      cliphist list |
        sed 's/\([0-9]*\)\t\(.*\)/\2\r\1/g' | # The \t is ugly
        rofi -dmenu -p '   Clip ' -theme ~/.config/rofi/clipboard.rasi |
        sed 's/\(.*\)\r\([0-9]*\)/\2\t\1/g' |
        cliphist decode |
        wl-copy
      ;;
    emoji)
      python3 ~/.config/hypr/bin/emoji.py list |
        rofi -dmenu -p ' 󰱨 Emoji ' -theme ~/.config/rofi/emoji.rasi |
        python3 ~/.config/rofi/bin/emoji.py decode |
        wl-copy
      ;;
    wifi)
      while true; do
        rofi-wifi-menu-do || break
      done
      ;;
    bluetooth)
      return
      ;;
  esac
}

main "${@}"
