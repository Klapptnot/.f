#! /bin/env bash

# Function to display a nice functional progress bar
pbar() {
  [ "${#}" -eq 0 ] && return
  local LEFT=false
  local CENTERED=false
  local REMOVE_BAR=true
  local LINEBREAK=false
  local CHAR="•" # █
  local TERM_WIDTH=""
  local HINT=""
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -h | --hint)
        HINT=${2}
        shift 2
        ;;
      -e | --char)
        [ "${#2}" -eq 1 ] && CHAR="${2}"
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
        REMOVE_BAR=false
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

  [ -z "${TERM_WIDTH}" ] && TERM_WIDTH=$(tput cols)
  local BAR_SIZES=(200 100 50 20 10)

  local WIDTH
  for w in "${BAR_SIZES[@]}"; do
    (((${#HINT} + w) + 7 <= TERM_WIDTH)) && {
      WIDTH="${w}"
      break
    }
  done

  local LAST_STEP=0
  local BAR_PROGRESS_CHARS=""
  local LAST_LINE=""
  local CURRENT_STEP=""

  while true; do
    # Check if data is available on stdin (non-blocking)
    read -r -t 0.1 CURRENT_STEP || continue
    if [ -z "${CURRENT_STEP}" ] || [[ "${CURRENT_STEP}" != "[::pb.draw::] "* ]]; then
      printf '\x1b[0K\x1b[0G%s\n%s' "${CURRENT_STEP}" "${LAST_LINE}" # Repeat logs
      continue
    fi

    CURRENT_STEP="${CURRENT_STEP:14:${#CURRENT_STEP}}"
    ((CURRENT_STEP <= LAST_STEP)) && continue
    TERM_WIDTH=$(tput cols)

    # Enable auto-resizing when window resize occurs
    for w in "${BAR_SIZES[@]}"; do
      if (((${#HINT} + w) + 7 <= TERM_WIDTH)); then
        WIDTH="${w}"
        # Set to 0 to redraw
        LAST_STEP=0
        BAR_PROGRESS_CHARS=""
        LAST_LINE="${w}"
        break
      fi
    done

    # shellcheck disable=SC2183
    if ${CENTERED}; then
      local margin=$(((TERM_WIDTH - (WIDTH + 7)) / 2))
      (((margin % 2) != 0)) && margin=$((margin - 1))

      printf -v SHOW_HINT "%s%*s" "${HINT}" $((margin - ${#HINT}))

    elif [ -n "${HINT}" ]; then
      ((((${#HINT} + WIDTH) + 7) > TERM_WIDTH)) && HINT="| "
    fi

    local CHR_PL="${CHAR}"
    local PAD_SPC=${WIDTH}
    local DISPLAY_STEP_NUM=${CURRENT_STEP}
    local AUGME=1
    case ${WIDTH} in
      200)
        CHR_PL="${CHAR}${CHAR}"
        ${LEFT} && DISPLAY_STEP_NUM=$(((WIDTH / 2) - CURRENT_STEP))
        ;;
      100)
        ${LEFT} && DISPLAY_STEP_NUM=$((WIDTH - CURRENT_STEP))
        ;;
      50)
        AUGME=2
        ${LEFT} && DISPLAY_STEP_NUM=$(((WIDTH * 2) - CURRENT_STEP))
        ;;
      20)
        AUGME=5
        ${LEFT} && DISPLAY_STEP_NUM=$(((WIDTH * 5) - CURRENT_STEP))
        ;;
      10)
        AUGME=10
        ${LEFT} && DISPLAY_STEP_NUM=$(((WIDTH * 10) - CURRENT_STEP))
        ;;
    esac

    for ((i = LAST_STEP; i < CURRENT_STEP; i += AUGME)); do
      ((PAD_SPC -= 1))
      read -r rnum < <(od -An -N1 -tu1 /dev/urandom)
      BAR_PROGRESS_CHARS+="\x1b[38;5;${rnum}m${CHR_PL}\x1b[0m"
      ((WIDTH == 200)) && ((PAD_SPC -= 1))
    done

    LAST_STEP=${CURRENT_STEP}

    printf -v LAST_LINE "\x1b[0K%s[%b%${PAD_SPC}s] %4s\x1b[0G" "${SHOW_HINT}" "${BAR_PROGRESS_CHARS}" "" "${DISPLAY_STEP_NUM}%"
    printf '%s' "${LAST_LINE}"

    ((CURRENT_STEP < 100)) && continue
    break
  done
  ${REMOVE_BAR} && printf '\x1b[0K\x1b[0G'
  ${LINEBREAK} && printf "\n"
  return 0
}
