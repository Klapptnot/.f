#!/usr/bin/env bash

# Small utility to go to folders by alias

# Check if this script is being executed as the main script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Break execution
  printf "[\x1b[38;05;160m*\x1b[00m] This script is not made to run as a normal script\n"
  exit 1
fi

# shellcheck disable=SC1090
source ~/.config/bash/lib/printfc.sh

function goto {
  if [ -z "${1}" ]; then
    cd "${HOME}" &> /dev/null || return
    return
  fi
  local print_path=false
  if [[ "${1}" =~ ^-p|--print$ ]]; then
    print_path=true
    shift 1
  elif [[ "${1}" =~ ^-h|--help$ ]]; then
    local help=(
      '{f87}goto{r} - Alias based fast cd (change dir)\n'
      'Usage: goto <path|alias> [...MODIFIERS]\n'
      '       goto -h|--help\n'
      '       goto -l|--list\n'
      'Example\n'
      '  # go to folder with alias "nf"\n'
      '  goto nf\n'
      '  # format "of" alias with "images"\n'
      '  goto of images\n'
      '  # go to home folder\n'
      '  goto\n'
    )
    # Join without separation
    IFS= printfc "${help[*]}"
    return
  elif [[ "${1}" =~ ^-l|--list$ ]]; then
    if ! [ -f ~/.config/dotf/goto.idx ]; then
      printfc '{f85}[INFO]{r} Index file not found, printing default aliases\n'
      PATH_INDEX_CONTENT=(
        'cfg   &!HOME;/.config'
        'ubin  /usr/bin'
        'ulib  /usr/lib'
        'uetc  /usr/etc'
        'dtkp  &!HOME;/Desktop'
        'nvc   &*cfg;/nvim'
      )
      # shellcheck disable=SC2178
      IFS=$'\n' PATH_INDEX_CONTENT="${PATH_INDEX_CONTENT[*]}"
      # shellcheck disable=SC2128
      printf '%s\n' "${PATH_INDEX_CONTENT}"
      return
    fi
    printfc '{f85}[INFO]{r} Printing aliases\n%s\n' "$(< ~/.config/dotf/goto.idx)"
    return
  fi

  if [ -f ~/.config/dotf/goto.idx ]; then
    # shellcheck disable=SC2178
    declare -r PATH_INDEX_CONTENT="$(< ~/.config/dotf/goto.idx)"
  else
    # Set a default config, but give a warning
    PATH_INDEX_CONTENT=(
      'cfg &!HOME;/.config'
      'ubin /usr/bin'
      'ulib /usr/lib'
      'uetc /usr/etc'
      'dtkp &!HOME;/Desktop'
      'nvc  &*cfg;/nvim'
    )
    # Join by LF
    # shellcheck disable=SC2178
    IFS=$'\n' PATH_INDEX_CONTENT="${PATH_INDEX_CONTENT[*]}"
    # shellcheck disable=SC2178,SC2128
    declare -r PATH_INDEX_CONTENT="${PATH_INDEX_CONTENT}"
    printfc '{f191}[WARN]{r} Index file no found, default aliases is set\n'
  fi

  # shellcheck disable=SC2128
  PATH_INDEX="$(awk '{ print $1 }' <<< "${PATH_INDEX_CONTENT}")"
  local alias=()
  while read -r a; do alias+=("${a}"); done <<< "${PATH_INDEX}"
  declare -A ALIASES
  while read -r p; do
    declare ALIASES["${alias[0]}"]="${p}"
    alias=("${alias[@]:1}")
  done <<< "$(grep -Po "(?<=\s)[^\s].*(?=$)" <<< "${PATH_INDEX_CONTENT}")"
  local modifiers=("${@:2}")
  local ent_regex='&(\*|!|%)([^;\s]*);'
  local path="${ALIASES[${1}]}"
  if [ -z "${path}" ]; then
    printfc '{f160}[ERR ]{r} Alias "%s" not found\n' "${1}"
    return 2
  fi
  local shopt_restore=false
  if shopt -q patsub_replacement; then
    shopt -u patsub_replacement
    shopt_restore=true
  fi
  while [[ ${path} =~ ${ent_regex} ]]; do
    case "${BASH_REMATCH[1]}" in
      '*')
        if [ -z "${ALIASES[${BASH_REMATCH[2]}]}" ]; then
          printfc '{f160}[ERR ]{r} Alias "%s" not found\n' "${BASH_REMATCH[2]}"
          return 2
        fi
        path="${path//${BASH_REMATCH[0]}/${ALIASES["${BASH_REMATCH[2]}"]}\/}"
        ;;
      '!')
        if [ -z "${BASH_REMATCH[2]}" ]; then
          printfc '{f160}[ERR ]{r} Environment variable "%s" inaccessible\n' "${BASH_REMATCH[2]}"
          return 3
        fi
        path="${path//${BASH_REMATCH[0]}/${!BASH_REMATCH[2]}\/}"
        ;;
      '%')
        if [ -z "${modifiers[(${BASH_REMATCH[2]} - 1)]}" ]; then
          # shellcheck disable=SC2004
          printfc '{f160}[ERR ]{r} Modifiers number "%s" not found\n' "$((${BASH_REMATCH[2]} - 1))"
          return 4
        fi
        path="${path//${BASH_REMATCH[0]}/${modifiers[(${BASH_REMATCH[2]} - 1)]}\/}"
        modifiers=(
          "${modifiers[@]:0:${BASH_REMATCH[2]}-1}"
          "${modifiers[@]:${BASH_REMATCH[2]}}"
        )
        ;;
    esac
  done
  if ${shopt_restore}; then
    shopt -s patsub_replacement
  fi
  for ((i = 0; i < ${#modifiers[@]}; i++)); do
    path="${path}/${modifiers[i]}"
  done
  if ! [ -d "${path}" ]; then
    printfc '{f160}[ERR ]{r} Folder "%s" does not exist or is not accessible\n' "${path}"
    return 7
  fi
  if ${print_path}; then
    printf '%s' "${path}"
  else
    cd "${path}" &> /dev/null || return
  fi
}
