#! /bin/env bash

# Decode some HTML entities
function str.html_entity_unicode_decode_basic() {
  sed \
    -e 's/&quot;/"/g' \
    -e "s/&apos;/'/g" \
    -e 's/&lt;/</g' \
    -e 's/&gt;/>/g' \
    -e 's/&nbsp;/ /g' \
    -e 's/&ndash;/-/g' \
    -e 's/&mdash;/--/g' \
    -e "s/&lsquo;/\'/g" \
    -e "s/&rsquo;/\'/g" \
    -e 's/&ldquo;/"/g' \
    -e 's/&rdquo;/"/g' \
    -e 's/&amp;/\&/g' <<< "${*}"
}
# Decode all Perl supported HTML entities
function str.html_entity_decode_perl() {
  perl -MHTML::Entities -pe 'decode_entities($_);' <<< "${*}"
}
# Decode ASCII HTML entities
function str.html_entity_ascii_decode() {
  local __an="${*}"
  while [[ ${__an} =~ \&#([0-9]+)\; ]]; do
    __an="${__an//${BASH_REMATCH[0]}/\\u$(printf '%04x' "${BASH_REMATCH[1]}")}"
  done
  printf "%b" "${__an}"
}
# Encode the whole string to ASCII HTML entities
function str.html_entity_ascii_encode() {
  local input="${*}"
  local encoded=""

  for ((i = 0; i < ${#input}; i++)); do
    printf -v encoded "%s&#%d;" "${encoded}" "'${input:i:1}"
  done
  printf '%s' "${encoded}"
}
# Encode string symbols to ASCII HTML entities
function str.html_entity_ascii_encode() {
  local input="${*}"
  local encoded=""

  for ((i = 0; i < ${#input}; i++)); do
    if [[ ! "${input:i:1}" =~ [[:punct:]] ]]; then
      printf -v encoded "%s" "${encoded}${input:i:1}"
      continue
    fi
    printf -v encoded "%s&#%d;" "${encoded}" "'${input:i:1}"
  done
  printf '%s' "${encoded}"
}
# Decode hex notation for url from string
function str.url_decode() {
  local __an="${*}"
  while [[ ${__an} =~ '%'([0-9]+)[^0-9] ]]; do
    echo "${BASH_REMATCH[*]}"
    __an="${__an//${BASH_REMATCH[0]}/\\u$(printf '%04x' "${BASH_REMATCH[1]}")}"
  done
  printf "%b" "${__an}"
}
# Encode the whole string to hex notation for url
function str.url_encode() {
  local input="${*}"
  local encoded=""

  for ((i = 0; i < ${#input}; i++)); do
    printf -v encoded "%s%%%x" "${encoded}" "'${input:i:1}"
  done
  printf '%s' "${encoded}"
}
# Encode string symbols to hex notation for url
function str.url_encode_symbols() {
  local input="${*}"
  local encoded=""

  for ((i = 0; i < ${#input}; i++)); do
    if [[ ! "${input:i:1}" =~ [[:punct:]] ]]; then
      printf -v encoded "%s" "${encoded}${input:i:1}"
      continue
    fi
    printf -v encoded "%s%%%x" "${encoded}" "'${input:i:1}"
  done
  printf '%s' "${encoded}"
}
# Return 0 if string ends with substring
# Usage: str.ends_with "string" "substring"
function str.ends_with() {
  [[ "${1}" =~ "${2}"$ ]]
}
# Return 0 if string starts with substring
# Usage: str.starts_with "string" "substring"
function str.starts_with() {
  [[ "${1}" =~ ^"${2}" ]]
}
# Return 0 if string contains substring
# Usage: str.contains "string" "substring"
function str.contains() {
  # shellcheck disable=SC2076
  [[ "${1}" =~ "${2}" ]]
}
# Return 0 if the string is null or empty
# Usage: str.null_empty "string"
function str.null_empty() {
  [[ -z "${1}" || "${1}" =~ ^null|NULL|nil|undefined$ ]]
}
# Remove spaces from start and end
# Usage: str.strip "string"
function str.strip() {
  local string="${*}"
  string="${string%"${string##*[![:space:]]}"}"
  string="${string#"${string%%[![:space:]]*}"}"
  printf "%s" "${string}"
}

# Escape special characters in string for JSON
function str.json_escape() {
  local s="${*}"
  s="${s//\\/\\\\}"   # escape backslashes
  s="${s//\"/\\\"}"   # escape double quotes
  s="${s//\//\\\/}"   # escape forward slashes
  s="${s//$'\r'/\\r}" # escape carriage returns
  s="${s//$'\n'/\\n}" # escape newlines
  s="${s//$'\t'/\\t}" # escape tabs
  printf "%s" "$s"
}
# Unescape special characters in JSON
function str.json_unescape() {
  local s="${*}"
  s="${s//\\\\/\\}"  # unescape backslashes
  s="${s//\\\"/\"}"  # unescape double quotes
  s="${s//\\\//\/}"  # unescape forward slashes
  s="${s/\\r/$'\r'}" # unescape carriage returns
  s="${s/\\n/$'\n'}" # unescape newlines
  s="${s/\\t/$'\t'}" # unescape tabs
  printf "%s" "$s"
}

# Make shorter the JSON manipulation
# Usage:
#     str.json_get <selector> <default>
# Default value is not required
function str.json_get() {
  [ -z "${1}" ] && printf 'null' && return 1
  [ -n "${2}" ] && local default="${2}"
  # Return if selector does not start with a dot
  ! str.starts_with "${1}" "." && printf 'null' && return 1
  local value=""
  value=$(jq -rM "${1}" <<< "${JSON}" 2> /dev/null)
  if [[ -z "${value}" || "${value}" == "null" ]]; then
    printf "%s" "${default:-null}"
  else printf "%s" "${value}"; fi
}

# Convert colors from rgb and hex
function str.hex2rgb() {
  # Accepts '#784dFF' or '784dFF' colors
  local hex
  # Remove # from start, if there is one
  if str.starts_with "${1}" "#"; then hex=${1:1}; else hex=${1}; fi
  printf "rgb(%d,%d,%d)" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}
function str.rgb2hex() {
  # Accept 'rgb(244,23,90)' color
  # local rgb="${1:4}" && rgb="${rgb%?}"
  local rgb="${1:4:${#1}-2}"
  # This works as long as printf will print the result
  # instead of just exiting with a stderr message
  # shellcheck disable=SC2086
  printf '#%02x%02x%02x' ${rgb//,/\ } 2> /dev/null
  return 0 # Mask the return status code (printf will return > 0)
}
