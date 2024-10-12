#! /bin/env bash

function str.strip {
  local s=''
  s="$(< /dev/stdin)"
  [ "${1}" != "start" ] && s="${s%"${s##*[![:space:]\n]}"}"
  [ "${1}" != "end" ]   && s="${s#"${s%%[![:space:]\n]*}"}"
  printf "%s" "${s}"
}

