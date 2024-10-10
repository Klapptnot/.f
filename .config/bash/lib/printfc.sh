#! /bin/env bash

printfc() {
  local __format_str__="${1}"
  local __color_code__='\x1b[0m' # Default is reset
  while [[ ${__format_str__} =~ \{(0|r|rst)\} ]]; do
    __format_str__="${__format_str__//${BASH_REMATCH[0]}/${__color_code__}}"
  done
  while [[ ${__format_str__} =~ \{f([0-9]{1,3})\} ]]; do
    if [ "${BASH_REMATCH[1]}" -ge 0 ] && [ "${BASH_REMATCH[1]}" -le 255 ]; then
      __color_code__="\x1b[38;05;${BASH_REMATCH[1]}m"
    fi
    __format_str__="${__format_str__//${BASH_REMATCH[0]}/${__color_code__}}"
    __color_code__='\x1b[0m' # Default to reset
  done
  while [[ ${__format_str__} =~ \{b([0-9]{1,3})\} ]]; do
    if [ "${BASH_REMATCH[1]}" -ge 0 ] && [ "${BASH_REMATCH[1]}" -le 255 ]; then
      __color_code__="\x1b[48;05;${BASH_REMATCH[1]}m"
    fi
    __format_str__="${__format_str__//${BASH_REMATCH[0]}/${__color_code__}}"
    __color_code__='\x1b[0m' # Default to reset
  done
  # shellcheck disable=SC2059 # Don't use variables in format string
  printf "${__format_str__}" "${@:2}"
}
