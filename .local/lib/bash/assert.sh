#! /bin/bash

function assert() {
  # NOTE: The following code assumes that 0 == true and 1 == false
  # to match the behavior of the bash exit codes and not the binary boolean
  if [ "${#}" -eq 1 ]; then
    [[ "${1}" = 'false' || "${1}" = "1" ]] && echo "ASSERT: ${*}" && exit 1
    [[ "${1}" = 'true' || "${1}" = '0' ]] && return
  fi
  if ! test "${@}"; then
    [ "${#}" -eq 0 ] && set -- NULL
    echo "ASSERT: ${*}"
    exit 1
  fi
}
