#! /bin/env bash

# |>----|>----|>----|><-><|----<|----<|----<|
# |>    from Klapptnot's Hyprland setup    <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# Force kill current window or all windows but current

if [ "${1}" == "current" ]; then
  jq --null-input \
    --argjson c "$(hyprctl clients -j)" \
    --argjson w "$(hyprctl activeworkspace -j)" \
    '$c[] | select(.workspace.id == $w.id) | select(.focusHistoryID == 0) | .pid' |
    xargs kill
else
  jq --null-input \
    --argjson c "$(hyprctl clients -j)" \
    --argjson w "$(hyprctl activeworkspace -j)" \
    '$c[] | select(.workspace.id == $w.id) | select(.focusHistoryID != 0) | .pid' |
    xargs kill
fi
