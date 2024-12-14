#!/usr/bin/bash

# Display a nice functional progress bar
# Usage: rsum [options]
#   -l, --label     Opt<str> default: ""    -> bar label
#   -c, --char      Opt<str> default: "•"   -> char displayed
#   -k, --keep      (flag)   default: false -> keep bar when done
#   -L, --left      (flag)   default: false -> show progress left
#   -C, --centered  (flag)   default: false -> center the bar
#   -n, --linefeed  (flag)   default: false -> add \n when done
#
# Function must print '[::pb.draw::] <percentage>' to update bar
# Any other (stdin) input will be repeated
# Example:
# for ((i=0;i<=100;i++)); do
#   (((i % 5) == 0)) && printf 'Multiple of 5!\n'
#   printf '[::pb.draw::] %d\n'
# done | pbar -l 'Test label'
function pbar {
  [ "${#}" -eq 0 ] && return
  local LEFT=false
  local CENTERED=false
  local REMOVE_BAR=true
  local LINEBREAK=false
  local CHAR="•" # █
  local TERM_WIDTH=""
  local LABEL=""
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -l | --label)
        LABEL="${2}"
        shift 2
        ;;
      -c | --char)
        [ "${#2}" -eq 1 ] && CHAR="${2}"
        shift 2
        ;;
      -L | --left)
        LEFT=true
        shift 1
        ;;
      -C | --centered)
        CENTERED=true
        shift 1
        ;;
      -k | --keep)
        REMOVE_BAR=false
        shift 1
        ;;
      -n | --linefeed)
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
    (((${#LABEL} + w) + 7 <= TERM_WIDTH)) && {
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
      if (((${#LABEL} + w) + 7 <= TERM_WIDTH)); then
        WIDTH="${w}"
        # Set to 0 to redraw
        LAST_STEP=0
        BAR_PROGRESS_CHARS=""
        LAST_LINE="${w}"
        break
      fi
    done

    local SHOW_LABEL="${LABEL}"
    # shellcheck disable=SC2183
    if ${CENTERED}; then
      local margin=$(((TERM_WIDTH - (WIDTH + 7)) / 2))
      (((margin % 2) != 0)) && margin=$((margin - 1))

      printf -v SHOW_LABEL "%s%*s" "${LABEL}" $((margin - ${#LABEL}))

    elif [ -n "${LABEL}" ]; then
      ((((${#LABEL} + WIDTH) + 7) > TERM_WIDTH)) && SHOW_LABEL="| "
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

    printf -v LAST_LINE "\x1b[0K%s[%b%${PAD_SPC}s] %4s\x1b[0G" "${SHOW_LABEL}" "${BAR_PROGRESS_CHARS}" "" "${DISPLAY_STEP_NUM}%"
    printf '%s' "${LAST_LINE}"

    ((CURRENT_STEP < 100)) && continue
    break
  done
  ${REMOVE_BAR} && printf '\x1b[0K\x1b[0G'
  ${LINEBREAK} && printf "\n"
  return 0
}
