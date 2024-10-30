#!/urs/bin/env bash

source ~/.config/bash/lib/str/uri_encode.sh

# Genreate a URI param string based on a associative array
# Usage:
#   str.uri_params "<associative_array_name>"
# Example:
# ```bash
#   declare -A params=( [query]="White houses" [tags]="house,white,village" )
#   read -r param_str < <(str.uri_params "params")
#
#   # params_str will contain:
#   # query=White%houses&tags=house%2Cwhite%2Cvillage
# ```
function str.uri_params {
  [ -z "${1}" ] && printf '' && return 1
  declare -n param_map="${1}"

  # local result=""
  local all=()
  for k in "${!param_map[@]}"; do
    read -r encoded_val < <(str.uri_encode <<<"${param_map[${k}]}")
    printf -v item '%s=%s' "${k}" "${encoded_val}"
    all+=("${item}")
  done
  local result="${all[*]}"

  printf "%s" "${result//\ /\&}"
}
