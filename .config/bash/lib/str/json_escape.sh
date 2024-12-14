#!/usr/bin/bash

# Usage:
#  str.json_escape <<< $'A string\n\tThat will be "escaped"'
function str.json_escape {
  : "$(< /dev/stdin)"
  : "${_//\\/\\\\}"   # escape backslashes
  : "${_//\"/\\\"}"   # escape double quotes
  : "${_//\//\\\/}"   # escape forward slashes
  : "${_//$'\r'/\\r}" # escape carriage returns
  : "${_//$'\n'/\\n}" # escape newlines
  : "${_//$'\t'/\\t}" # escape tabs
  printf "%s" "${_}"
}
