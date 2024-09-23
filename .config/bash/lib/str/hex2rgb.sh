function str.hex2rgb {
  # Accepts '#784dFF' or '784dFF' colors
  set -- "$(cat -)"
  local hex
  # Remove # from start, if there is one
  if [[ "${1}" == "#"* ]]; then hex=${1:1}; else hex=${1}; fi
  printf "rgb(%d,%d,%d)" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}
