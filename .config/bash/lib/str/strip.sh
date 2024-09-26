function str.strip {
  local string=''
  string="$(cat -)"
  [ "${1}" != "start" ] && string="${string%"${string##*[![:space:]\n]}"}"
  [ "${1}" != "end" ]   && string="${string#"${string%%[![:space:]\n]*}"}"
  printf "%s" "${string}"
}

