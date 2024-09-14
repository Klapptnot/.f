function str.json_escape {
  : "$(cat -)"
  : "${_//\\/\\\\}"   # escape backslashes
  : "${_//\"/\\\"}"   # escape double quotes
  : "${_//\//\\\/}"   # escape forward slashes
  : "${_//$'\r'/\\r}" # escape carriage returns
  : "${_//$'\n'/\\n}" # escape newlines
  : "${_//$'\t'/\\t}" # escape tabs
  printf "%s" "${_}"
}
