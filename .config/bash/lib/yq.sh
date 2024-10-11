#! /bin/env bash

# Simple YAML value reader, currently only useful
# for YAML files with 2 spaces for indentation
# NO SUPPORT FOR SETS, TAGS, SCALARS, etc.
# ONLY KEY-VALUE, for arrays, strings and integers
yq.sh() {
  local path="${1}"
  local file="${2}"

  if [ -z "${file}" ] || [ "${file}" == '-' ]; then
    file="/dev/stdin"
  fi

  mapfile -t lines < "${file}"
  path="${path//\]/}"
  path="${path//\[/.}"
  IFS='.' read -ra dpa <<< "${path}"
  # Allow .name and name
  [ -z "${dpa[0]}" ] && local dpa=("${dpa[@]:1}")

  local fpa=()
  local last_ci=-1
  local ci=0
  local k=''
  local v=''
  local cai=-1
  local pop_2=false
  local multiline=false
  local multiline_fold=false
  local multiline_strp=s
  local multiline_str=""
  local multiline_key=""
  local probably_key=false
  local keys=()
  local line mmode smode #imode
  local indent=2
  local RESULT=""
  for i in "${!lines[@]}"; do
    line="${lines[i]}"
    case "${line}" in
      '#'* | '---') continue ;;
      '') ${multiline} || continue ;;
    esac
    if ${multiline} && [ "${line}" != "" ]; then
      if [ -n "${multiline_str}" ]; then
        ${multiline_fold} && multiline_str+=" " || multiline_str+=$'\n'
      fi

      multiline_str+="${line:$((ci + indent)):${#line}}"
      continue
    elif ${multiline}; then
      multiline=false
      k="${multiline_key}"
      v="${multiline_str}"
      ${multiline_strp} && v="${v%"${v##*[![:space:]\n]}"}"
      ${multiline_fold} && v="${v%"${v##*[![:space:]\n]}"}"
      multiline_str=''
      multiline_key=''
    else
      IFS=':' read -r key val <<< "${line}"
      k="${key#"${key%%[![:space:]]*}"}"
      # v="${val#*[[:space:]]}"
      v="${val:1}"
    fi

    : "${key%%[![:space:]]*}"
    ci="${#_}"

    if [[ "${k}" == '- '* ]]; then
      if [ -n "${v}" ]; then
        # list of objects
        # - key1: "value1"
        #   key2: "value2"
        ((ci = ci + indent))
        k="${k:${indent}}"
        pop_2=true
      else
        # Plain array
        # - "value1"
        # - "value2"
        v="${k:${indent}}"
        k=''
      fi

      if ((cai > -1)); then
        if ${pop_2}; then
          local last_index="${fpa[*]##*\ }"
          fpa=("${fpa[@]:0:$((${#fpa[@]} - 2))}")
        else
          unset 'fpa[-1]'
        fi
      fi
      ((cai = cai + 1))
      fpa+=("${cai}")
      ${probably_key} && keys+=("${cai}")
      if [ -n "${last_index}" ]; then
        fpa+=("${last_index}")
        last_index=''
      fi
    elif [[ "${v}" == '|'* ]] || [[ "${v}" == '>'* ]]; then
      # [>|][-+]?[0-9]*
      mmode="${v:0:1}" # |>
      smode="${v:1:1}" # -+
      # imode="${v:2}"   # 0-9
      multiline_key="${k}"
      multiline=true

      multiline_fold=false
      [ "${mmode}" == ">" ] && multiline_fold=true

      multiline_strp=false
      [ "${smode}" == "-" ] && multiline_strp=true
    fi

    # going a level less
    if ((last_ci > ci)); then
      # POP
      ((pa = ci / indent))
      last_ci=${ci}
      # replace current
      fpa=("${fpa[@]:0:${pa}}")
      [ -n "${k}" ] && fpa+=("${k}")
      cai=-1
      pop_2=false
      if ${probably_key}; then
        RESULT="${keys[*]}"
        break
      fi
    elif ((last_ci < ci)); then
      # ADD
      last_ci=${ci}
      [ -n "${k}" ] && fpa+=("${k}")
      [ -n "${k}" ] && ${probably_key} && keys+=("${k}")
    else
      # REP
      if [ -n "${line}" ]; then
        if ((cai < 0)) || ${pop_2}; then
          (("${#fpa[@]}" > 0)) && unset 'fpa[-1]'
          [ -n "${k}" ] && fpa+=("${k}")
          ${probably_key} && keys+=("${k}")
        fi
      fi
    fi

    ${multiline} && continue

    if [ "${fpa[*]}" == "${dpa[*]}" ]; then
      case "${v}" in
        "'"*"'" | '"'*'"') v="${v:1:$((${#v} - 2))}" ;;
      esac
      if [ -z "${v}" ]; then
        probably_key=true
      else
        RESULT="${v}"
      fi
    fi
  done

  if ${probably_key}; then
    RESULT="${keys[*]}"
  elif [ -n "${multiline_str}" ]; then
    if [ "${fpa[*]}" == "${dpa[*]}" ]; then
      RESULT="${multiline_str}"
    fi
  fi
  [ -z "${RESULT}" ] && return 1
  printf "%s" "${RESULT}"
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  yq.sh "${@}"
fi
