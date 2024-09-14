function str.markup_escape_all {
  local encoded=""
  : "$(cat -)"
  for ((i = 0; i < ${#_}; i++)); do
    printf -v encoded "%s&#%d;" "${encoded}" "'${_:i:1}"
  done
  printf '%s' "${encoded}"
}
