#!/usr/bin/bash

# Print passed strings horizontally aligned
# Usage:
#   pprint.list [strings]
# Example:
#   $ pprint.list Hello darkness my old friend I\'ve come to talk with you again
#   Hello     darkness  my        old
#   friend    I've      come      to
#   talk      with      you       again
function pprint.list {
  local items=("${@}")
  local count="${#items[@]}"
  read -r _ cols < <(stty size)
  local maxl=0
  for i in "${items[@]}"; do
    ((${#i} > maxl)) && maxl="${#i}"
  done
  local idl=$((maxl + 2))
  local iil=$((cols / idl))
  local i=1
  for it in "${items[@]}"; do
    printf "%-${idl}s" "${it}"
    (((i % iil) == 0)) && printf '\n'
    ((i++))
  done
  printf '\n'
}
