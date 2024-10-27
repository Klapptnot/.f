#!/usr/bin/env bash

# Usage:
#   str.json_unescape <<< 'A string\n\tThat will be \"unescaped\"'
function str.json_unescape {
  : "$(< /dev/stdin)"
  : "${_//\\\\/\\}"  # unescape backslashes
  : "${_//\\\"/\"}"  # unescape double quotes
  : "${_//\\\//\/}"  # unescape forward slashes
  : "${_/\\r/$'\r'}" # unescape carriage returns
  : "${_/\\n/$'\n'}" # unescape newlines
  : "${_/\\t/$'\t'}" # unescape tabs
  printf "%s" "${_}"
}
