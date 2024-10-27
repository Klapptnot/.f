#!/usr/bin/env bash

# Usage:
#   str.markup_unescape <<< 'escape &amp; &quot;quote&quot;&#63;' # escape & "quote"?
function str.markup_unescape {
  : "$(< /dev/stdin)"
  : "${_//&apos;/\'}"
  : "${_//&quot;/\"}"
  : "${_//&amp;/\&}"
  : "${_//&lt;/\<}"
  : "${_//&gt;/\>}"
  local s="${_}"
  while [[ "${s}" =~ \&#([0-9]+)\; ]]; do
    printf -v cv '%08x' "${BASH_REMATCH[1]}"
    s="${s//${BASH_REMATCH[0]}/"\\U${cv}"}"
  done
  printf "%b" "${s}"
}
