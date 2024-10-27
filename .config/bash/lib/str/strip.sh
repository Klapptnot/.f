#!/usr/bin/env bash

# Strip leading or trailing [:space:] from stdin input
# Usage:
#    str.strip start <<< "  Hi bro  " # "Hi bro  "
#    str.strip end   <<< "  Hi bro  " # "  Hi bro"
#    str.strip       <<< "  Hi bro  " # "Hi bro"
function str.strip {
  : "$(< /dev/stdin)"
  local s="${_}"
  [ "${1}" != "start" ] && s="${s%"${s##*[![:space:]\n]}"}"
  [ "${1}" != "end" ]   && s="${s#"${s%%[![:space:]\n]*}"}"
  printf "%s" "${s}"
}

