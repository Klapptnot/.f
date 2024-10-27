#!/usr/bin/env bash

# Print passed strings vertically aligned
# Usage:
#   pprint.vlist [strings]
# Example:
#   $ pprint.vlist * # Simulates `ls -A` using bash glob
#
#   $ pprint.vlist Hello darkness my old friend I\'ve come to talk with you again
#   Hello     old       come      with
#   darkness  friend    to        you
#   my        I've      talk      again
function pprint.vlist {
  local items=("${@}")
  local count="${#items[@]}"
  read -r _ cols < <(stty size)
  local maxl=0
  for i in "${items[@]}"; do
    ((${#i} > maxl)) && maxl="${#i}"
  done
  local idl=$((maxl + 2))
  local iil=$((cols / idl))
  local lines=()
  local lct=$(((count / iil) - 1))
  local lri=$((count % iil))
  local ln=0
  local i=0
  local c=1
  while true; do
    printf -v item "%-${idl}s" "${items[i]}"
    lines[ln]="${lines[ln]}${item}"
    ((i++))
    if ((ln == lct)); then
      if ((lri > 0)); then
        ((ln++))
        printf -v item "%-${idl}s" "${items[i]}"
        lines[ln]="${lines[ln]}${item}"
        ((lri--))
        ((i++))
      fi
      ((c++))
      ln=0
      ((c > iil)) && break
    else
      ((ln++))
    fi
  done
  printf '%s\n' "${lines[@]}"
}
