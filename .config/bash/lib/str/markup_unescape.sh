#!/usr/bin/env bash

function str.markup_unescape {
  : "$(< /dev/stdin)"
  : "${_//&apos;/\'}"
  : "${_//&quot;/\"}"
  : "${_//&amp;/\&}"
  : "${_//&lt;/\<}"
  : "${_//&gt;/\>}"
  while [[ ${_} =~ \&#([0-9]+)\; ]]; do
    : "${_//${BASH_REMATCH[0]}/\\U$(printf '%08x' "${BASH_REMATCH[1]}")}"
  done
  printf "%b" "${_}"
}
