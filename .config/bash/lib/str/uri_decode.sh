function str.uri_decode {
  : "$(cat -)"
  while [[ ${_} =~ %([0-9]+)[^0-9] ]]; do
    : "${_//${BASH_REMATCH[0]}/\\u$(printf '%02x' "${BASH_REMATCH[1]}")}"
  done
  printf "%b" "${_}"
}
