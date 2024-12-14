#!/usr/bin/bash

# Usage:
#   str.uri_decode <<< "I%20%F0%9F%92%9C%20bash" # I 💜 bash
function str.uri_decode {
  : "$(< /dev/stdin)"
  printf "%b" "${_//\%/\\x}"
}
