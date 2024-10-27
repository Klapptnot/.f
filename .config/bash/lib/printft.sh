#!/usr/bin/env bash

# printf wrapper to retrieve translations based on message ID and locale
# Needs to get translations files from global variable TRSTR_HOME
# DOES NOT SUPPORT printf FLAGS
# Example:
#   $ printft greeting.user "${USER:-${USERNAME}}"
#   $ printft root.perm.needed "${progname}"
# Where file for en_US is "${TRSTR_HOME}/en_US.lang" with
# greeting.user=Welcome again %s!!
# root.perm.needed=Root access needed, please restart %s with sudo.
function printft {
  if [[ -z "${TRSTR_HOME}" || ! -d "${TRSTR_HOME}" ]]; then return 1; fi

  local locale="${LANG%%.*}"
  local file="${TRSTR_HOME}/${locale}.lang"

  if [ ! -f "${file}" ]; then
    local file="${TRSTR_HOME}/en_US.lang" # Default language: en_US.lang
  fi

  # Read the translation file and retrieve the translation
  read -r msg < <(grep -E "^${1}=" "${file}" | cut -d'=' -f2-)
  if [ -n "${msg}" ]; then
    # shellcheck disable=SC2059,SC2210
    printf "${msg}" "${@:2}" 2> /dev/null
    # stderr to null, printf prints something anyway
    return
  fi
  return 1
}
