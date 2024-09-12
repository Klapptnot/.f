#!/bin/bash

function log {
  local level="${1,,}"
  local show_verbose_info=true
  ((${#level} > 1)) && show_verbose_info=false
  level="${level:0:1}"
  local format="${2}"
  shift 2

  declare -A log_colors=(
    ['d']='\x1b[32m'
    ['i']='\x1b[34m'
    ['w']='\x1b[33m'
    ['e']='\x1b[31m'
    ['c']='\x1b[30m\x1b[41m'
  )
  declare -A log_names=(
    ['d']='debug'
    ['i']='info'
    ['w']='warn'
    ['e']='error'
    ['c']='critical'
  )

  local color="${log_colors[${level}]}"
  test -z "${color}" && level="default"
  level="${log_names[${level}]}"
  test -z "${level}" && level="default"

  # shellcheck disable=SC2059
  printf -v message "${format}" "${@}"

  # Output the log message
  if ${show_verbose_info}; then
    printf '%b%s\x1b[0m\n' "${color}" "${message}"
  else
    printf '%b[%s] %s: %s\x1b[0m\n' "${color}" "$(date +%Y-%m-%d_%H:%M:%S)" "${level^^}" "${message}"
  fi
}
