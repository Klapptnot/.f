function str.strip {
  local string=''
  string="$(cat -)"
  string="${string%"${string##*[![:space:]\n]}"}"
  string="${string#"${string%%[![:space:]\n]*}"}"
  printf "%s" "${string}"
}

