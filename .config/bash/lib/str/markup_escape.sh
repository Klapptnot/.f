#!/usr/bin/env bash

# Usage:
#   str.markup_escape <<< 'escape & "quote"?' # escape &amp; &quot;quote&quot;&#63;
function str.markup_escape {
  : "$(< /dev/stdin)"
  local input="${_}"

  local encoded=""
  for ((i = 0; i < ${#input}; i++)); do
    if [[ "${input:i:1}" =~ [\'\"\&\<\>] ]]; then
      case ${input:i:1} in
        \') encoded="${encoded}&apos;" ;;
        \") encoded="${encoded}&quot;" ;;
        \&) encoded="${encoded}&amp;" ;;
        \<) encoded="${encoded}&lt;" ;;
        \>) encoded="${encoded}&gt;" ;;
      esac
    elif [[ ! "${input:i:1}" =~ [[:punct:]] ]]; then
      encoded="${encoded}${input:i:1}"
    else
      printf -v encoded "%s&#%d;" "${encoded}" "'${input:i:1}"
    fi
  done
  printf '%s' "${encoded}"
}
