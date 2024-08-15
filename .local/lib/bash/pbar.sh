#! /bin/env bash
# shellcheck disable=SC2155 # Masking allowed ($?)

# Function to display a nice functional progress bar
function pb.do() {
  [ "${#}" -eq 0 ] && return
  local LEFT=false
  local CENTERED=false
  local REMOVE_PBAR=true
  local LINEBREAK=false
  local UWIDTH=true
  local CHAR="•" # █
  local TERM_WIDTH=""
  local HINT=""
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -w | --width)
        local WIDTH=${2}
        shift 2
        ;;
      -h | --hint)
        HINT=${2}
        shift 2
        ;;
      -e | --char)
        [ "${#2}" -eq 1 ] && CHAR="${2}"
        shift 2
        ;;
      --term-width)
        TERM_WIDTH="${2}"
        UWIDTH=false
        shift 2
        ;;
      -l | --left)
        LEFT=true
        shift 1
        ;;
      -c | --centered)
        CENTERED=true
        shift 1
        ;;
      -k | --keep)
        REMOVE_PBAR=false
        shift 1
        ;;
      -n | --linebreak)
        LINEBREAK=true
        shift 1
        ;;
      *)
        shift 1
        ;;
    esac
  done

  local BAR_SIZES=(200 100 50 20 10)
  [ -n "${WIDTH}" ] && {
    # shellcheck disable=SC2076
    if ! [[ " ${BAR_SIZES[*]} " =~ " ${WIDTH} " ]] || [ "$(((${#HINT} + WIDTH) + 7))" -gt "${TERM_WIDTH}" ]; then
      unset WIDTH
    fi
  }
  [ -z "${TERM_WIDTH}" ] && TERM_WIDTH=$(tput cols)

  ${UWIDTH} && [ -z "${WIDTH}" ] && {
    for w in "${BAR_SIZES[@]}"; do
      [ "$(((${#HINT} + w) + 7))" -le "${TERM_WIDTH}" ] && {
        WIDTH="${w}"
        break
      }
    done
  }

  # if [[ -p /dev/stdin ]]; then
  #   # STDIN="$(cat -)"
  #   read -r STDIN
  # fi

  local PROGRESS_OLD=0
  local PBAR_STR=""
  local LAST_DRAW=""

  # [ "$(((${#HINT} + WIDTH) + 7))" -gt "${TERM_WIDTH}" ] && {/**/}

  while true; do
    # Check if data is available on stdin (non-blocking)
    read -r -t 0.1 PROGRESS || continue
    if [ -z "${PROGRESS}" ] || [[ "${PROGRESS}" != "[::pb.draw::] "* ]]; then
      printf '\x1b[0K\x1b[0G%s\n%s' "${PROGRESS}" "${LAST_DRAW}" # Repeat logs
      continue
    fi
    PROGRESS="${PROGRESS:14:${#PROGRESS}}"
    [ "${PROGRESS}" -le "${PROGRESS_OLD}" ] && continue

    # Enable auto-resizing when window resize occurs
    for W in "${BAR_SIZES[@]}"; do
      if [ "$(((${#HINT} + W) + 7))" -le "${TERM_WIDTH}" ]; then
        WIDTH="${W}"
        if [ "${LAST_DRAW}" != "${LAST_DRAW}" ]; then
          # Set to 0 to redraw
          PROGRESS_OLD=0
          PBAR_STR=""
        fi
        LAST_DRAW="${W}"
        break
      fi
    done

    if [ "${PROGRESS_OLD}" -eq 0 ]; then
      # shellcheck disable=SC2183
      if ${CENTERED}; then
        local margin=$(((TERM_WIDTH - (WIDTH + 7)) / 2))
        if [ "$((margin % 2))" -ne 0 ]; then
          margin=$((margin - 1))
        fi
        [ -n "${HINT}" ] && {
          HINT=$(printf "%s%*s" "${HINT}" $((margin - ${#HINT})))
        } || HINT=$(printf "%*s" "${margin}")
      elif [ -n "${HINT}" ]; then
        [ "$(((${#HINT} + WIDTH) + 7))" -gt "${TERM_WIDTH}" ] && HINT="| "
      fi
    fi

    local CHR_PL=""
    local PAD_SPC=0
    local PROGRESS_NUM=${PROGRESS}
    case ${WIDTH} in
      200)
        CHR_PL="${CHAR}${CHAR}"
        ${LEFT} && PROGRESS_NUM=$(((WIDTH / 2) - PROGRESS))
        PAD_SPC=$((WIDTH - (PROGRESS * 2)))
                                             ;;
      100)
        CHR_PL="${CHAR}"
        ${LEFT} && PROGRESS_NUM=$((WIDTH - PROGRESS))
        PAD_SPC=$((WIDTH - PROGRESS))
                                       ;;
      50)
        CHR_PL="${CHAR}"
        ${LEFT} && PROGRESS_NUM=$(((WIDTH * 2) - PROGRESS))
        PAD_SPC=$((WIDTH - (PROGRESS / 2)))
                                             ;;
      20)
        CHR_PL="${CHAR}"
        ${LEFT} && PROGRESS_NUM=$(((WIDTH * 5) - PROGRESS))
        PAD_SPC=$((WIDTH - (PROGRESS / 5)))
                                             ;;
      10)
        CHR_PL="${CHAR}"
        ${LEFT} && PROGRESS_NUM=$(((WIDTH * 10) - PROGRESS))
        PAD_SPC=$((WIDTH - (PROGRESS / 10)))
                                              ;;
    esac

    for ((i = PROGRESS_OLD; i < PROGRESS; i++)); do
      local rnum=$(od -An -N1 -tu1 /dev/urandom)
      PBAR_STR+="\x1b[38;5;${rnum#*\ }m${CHR_PL}\x1b[0m"
    done
    PROGRESS_OLD=${PROGRESS}

    LAST_DRAW=$(printf "\x1b[0K%s[%b%${PAD_SPC}s] %4s\x1b[0G" "${HINT}" "${PBAR_STR}" "" "${PROGRESS_NUM}%")
    printf '%s' "${LAST_DRAW}"

    ${LEFT} && [[ ${PROGRESS} -gt 1 ]] && continue
    ! ${LEFT} && [[ ${PROGRESS} -lt 100 ]] && continue

    break
  done
  ${REMOVE_PBAR} && printf '\x1b[0K\x1b[0G'
  ${LINEBREAK} && printf "\n"
  echo >&2
}
