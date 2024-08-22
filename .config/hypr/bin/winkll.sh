#! /bin/env bash

# |>----|>----|>----|><-><|----<|----<|----<|
# |>    from Klapptnot's Hyprland setup    <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# Force kill current window or all windows but current
# Inspired on
# https://www.reddit.com/r/hyprland/comments/1eg4yi8/share_your_kill_all_window_but_current_in_current/
# The commands shared on this post will kill all windows from the same PID
# So, this closes windows and processes

function main {
  local opr="${1}"
  shift 1

  if [[ ! "${opr}" =~ ^(kill|close)-(current|others)$ ]]; then
    printf '\x1b[31mThe command "%s" is not a know operation\x1b[0m\n' "${opr}"
    exit
  fi

  "${opr}"
}

function close-others {
  while read -r window; do
    hyprctl dispatch closewindow "${window}"
  done < <(jq -rM --null-input \
    --argjson c "$(hyprctl clients -j)" \
    --argjson w "$(hyprctl activeworkspace -j)" \
    '$c[] | select(.workspace.id == $w.id) | select(.focusHistoryID != 0) | "address:" + .address'
  )
}

function kill-others {
  jq -rM --null-input \
    --argjson c "$(hyprctl clients -j)" \
    --argjson w "$(hyprctl activeworkspace -j)" \
    '$c[] | select(.workspace.id == $w.id) | select(.focusHistoryID != 0) | .pid' |
    xargs kill
}

function close-current {
  jq --null-input \
    --argjson c "$(hyprctl clients -j)" \
    --argjson w "$(hyprctl activeworkspace -j)" \
    '$c[] | select(.workspace.id == $w.id) | select(.focusHistoryID == 0) | "address:" + .address' |
    xargs hyprctl dispatch closewindow
}

function kill-current {
  jq --null-input \
    --argjson c "$(hyprctl clients -j)" \
    --argjson w "$(hyprctl activeworkspace -j)" \
    '$c[] | select(.workspace.id == $w.id) | select(.focusHistoryID == 0) | .pid' |
    xargs kill
}

main "${@}"
