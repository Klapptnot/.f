function str.json_unescape {
  : "$(cat -)"
  : "${_//\\\\/\\}"  # unescape backslashes
  : "${_//\\\"/\"}"  # unescape double quotes
  : "${_//\\\//\/}"  # unescape forward slashes
  : "${_/\\r/$'\r'}" # unescape carriage returns
  : "${_/\\n/$'\n'}" # unescape newlines
  : "${_/\\t/$'\t'}" # unescape tabs
  printf "%s" "${_}"
}

