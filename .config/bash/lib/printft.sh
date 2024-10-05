#! /bin/env bash

# Function to retrieve translations based on message ID and locale
# Needs to get translations files from global variable TRSTR_HOME
# ${1}       Format string ID
# ${@:2}     Strings to fill format
printft() {
  if [[ -z "${TRSTR_HOME}" || ! -d "${TRSTR_HOME}" ]]; then return 1; fi

  local locale="${LANG%%.*}"
  local file="${TRSTR_HOME}/${locale}.lang"

  if [ ! -f "${file}" ]; then
    local file="${TRSTR_HOME}/en_US.lang" # Default language: en_US.lang
  fi

  # Read the translation file and retrieve the translation
  # Command substitution should be faster with large output
  # and equal as subshell if not, but idk
  # I've never seen if it's true/false
  # Also read gets only one line
  read -r msg < <(grep -E "^${1}=" "${file}" | cut -d'=' -f2-)
  if [ -n "${msg}" ]; then
    # shellcheck disable=SC2059,SC2210
    printf "${msg}" "${@:2}" 2> /dev/null
    # stderr to null, printf prints something anyway
    return
  fi
  return 1
}
