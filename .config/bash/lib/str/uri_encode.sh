#!/usr/bin/env bash

# Usage:
#   str.uri_encode <<< "I 💜 bash" # I%20%F0%9F%92%9C%20bash
function str.uri_encode {
  local input=''
  input="$(< /dev/stdin)"

  local encoded=""
  local LC_ALL=C # support unicode = loop bytes, not characters
  for ((i = 0; i < ${#input}; i++)); do
    # Python's urllib.parse.quote leaves `/` without encoding
    if [[ "${input:i:1}" =~ ^[a-zA-Z0-9.~_-]$ ]]; then
      printf -v encoded "%s%s" "${encoded}" "${input:i:1}"
    else
      printf -v encoded "%s%%%02X" "${encoded}" "'${input:i:1}"
    fi
  done
  printf '%s' "${encoded}"
}
