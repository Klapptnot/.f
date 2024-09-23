#! /bin/env bash
function yq.sh {
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
  for line in "${lines[@]}"; do
    case "${line}" in
      '' | '#'* | '---') continue ;;
    esac
    IFS=':' read -r key val <<< "${line}"
    k="${key#"${key%%[![:space:]]*}"}"
    v="${val#*[[:space:]]}"

    : "${key%%[![:space:]]*}"
    ci="${#_}"

    if [[ "${k}" == '- '* ]]; then
      # echo ARRAY on "${line}" ======= ${cai}
      if [ -n "${v}" ]; then
        # list of objects
        # - key1: "value1"
        #   key2: "value2"
        ((ci = ci + 2))
        k="${k:2}"
        pop_2=true
      else
        # Plain array
        # - "value1"
        # - "value2"
        v="${k:2}"
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
      if [ -n "${last_index}" ]; then
        fpa+=("${last_index}")
        last_index=''
      fi
    fi

    # going a level less
    if ((last_ci > ci)); then
      # echo "POP ${last_ci} -> ${ci} ${key}"
      ((pa = ci / 2))
      last_ci=${ci}
      # replace current
      fpa=("${fpa[@]:0:${pa}}")
      [ -n "${k}" ] && fpa+=("${k}")
      cai=-1
      pop_2=false
    elif ((last_ci < ci)); then
      # echo "ADD ${last_ci} -> ${ci} ${key}"
      last_ci=${ci}
      [ -n "${k}" ] && fpa+=("${k}")
    else
      if ((cai < 0)) || ${pop_2}; then
        # echo "REP ${last_ci} -> ${ci} ${key}"
        (("${#fpa[@]}" > 0)) && unset 'fpa[-1]'
        [ -n "${k}" ] && fpa+=("${k}")
      fi
    fi

    if [ "${fpa[*]}" == "${dpa[*]}" ]; then
      case "${v}" in
        "'"*"'" | '"'*'"') v="${v:1:$((${#v} - 2))}" ;;
      esac
      printf '%s' "${v}"
      break
    fi
  done
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  yq.sh "${@}"
fi
