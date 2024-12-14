#!/usr/bin/bash

# Usage:
#   str.hex2rgb <<< "#784dFF" # rgb(120,77,255)
function str.hex2rgb {
  # Accepts '#784dFF' or '784dFF' colors
  local hex
  hex="$(< /dev/stdin)"
  # Remove # from start, if there is one
  [[ "${hex}" == "#"* ]] && hex=${hex:1}
  printf "rgb(%d,%d,%d)" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}
