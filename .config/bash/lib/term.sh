#! /bin/env bash

function term.color.from_hex {
  read -r s < /dev/stdin
  [[ "${s}" == '#'* ]] && s="${s:1}"
  [[ "${s}" =~ ^[a-fA-F0-9]{6}$ ]] && printf '\x1b[0m' && return

  local r=$((16#${s:1:2}))
  local g=$((16#${s:3:2}))
  local b=$((16#${s:5:2}))

  local format='\x1b[38;2;%d;%d;%dm'
  [ -n "${1}" ] && format='\x1b[48;2;%d;%d;%dm'
  # shellcheck disable=SC2059
  printf "${format}" "${r}" "${g}" "${b}"
}

function term.cursor.go_up {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}A"
}

function term.cursor.go_down {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}B"
}

function term.cursor.go_right {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}C"
}

function term.cursor.go_left {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}D"
}

function term.cursor.go_to {
  local l=${1:-1}
  local c=${2:-1}
  ! [[ ${c} =~ ^[0-9]+$ ]] && c=1
  ! [[ ${l} =~ ^[0-9]+$ ]] && l=1
  printf "%b" "\x1b[${l};${c}H"
}

function cursos.pos {
  local pos="0;0"
  IFS='[' read -p $'\e[6n' -d R -rs _ pos
  printf "%s" "${pos}"
}

term.cursor.save() { printf '\x1b7'; }
term.cursor.back() { printf '\x1b8'; }
term.cursor.home() { printf '\x1b[0H'; }

function term.cursor.line.end {
  read -r _ cols < <(stty size)
  printf '\x1b[%dG' "${cols}";
}
term.cursor.line.home() { printf '\x1b[1G'; }

function term.cursor.linefeed {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}E"
}

function term.cursor.linebackfeed {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}F"
}

term.cursor.hide() { printf '\x1b[?25l'; }
term.cursor.show() { printf '\x1b[?25h'; }

term.size() { stty size; }

term.clear_line() { printf '\x1b[0G\x1b[0K'; }
term.clear_below() { printf '\x1b[0G\x1b[0J'; }
term.clear() { printf '\x1b[0H\x1b[2J'; }
term.clear_all() { printf '\x1b[0H\x1b[3J'; }

term.wrap.on() { printf '\x1b[?7h'; }
term.wrap.off() { printf '\x1b[?7l'; }

term.style.bold.on() { printf '\x1b[1m'; }
term.style.bold.off() { printf '\x1b[21m'; }
term.style.dimmed.on() { printf '\x1b[2m'; }
term.style.dimmed.off() { printf '\x1b[22m'; }
term.style.italic.on() { printf '\x1b[3m'; }
term.style.italic.off() { printf '\x1b[23m'; }
term.style.underlined.on() { printf '\x1b[4m'; }
term.style.underlined.off() { printf '\x1b[24m'; }
term.style.blink.on() { printf '\x1b[5m'; }
term.style.blink.off() { printf '\x1b[25m'; }
term.style.invert_color.on() { printf '\x1b[7m'; }
term.style.invert_color.off() { printf '\x1b[27m'; }
term.style.hidden.on() { printf '\x1b[8m'; }
term.style.hidden.off() { printf '\x1b[28m'; }
term.style.strikethrough.on() { printf '\x1b[9m'; }
term.style.strikethrough.off() { printf '\x1b[29m'; }

term.save() { printf '\e[?1049h'; }
term.back() { printf '\e[?1049l'; }
