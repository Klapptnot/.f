#! /bin/env bash

color.from_hex() {
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

cursor.go_up() {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}A"
}

cursor.go_down() {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}B"
}

cursor.go_right() {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}C"
}

cursor.go_left() {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}D"
}

cursor.go_to() {
  local l=${1:-1}
  local c=${2:-1}
  ! [[ ${c} =~ ^[0-9]+$ ]] && c=1
  ! [[ ${l} =~ ^[0-9]+$ ]] && l=1
  printf "%b" "\x1b[${l};${c}H"
}

cursos.pos() {
  local pos="0;0"
  IFS='[' read -p $'\e[6n' -d R -rs _ pos
  printf "%s" "${pos}"
}

cursor.save() { printf '\x1b7'; }
cursor.back() { printf '\x1b8'; }
cursor.home() { printf '\x1b[0H'; }

cursor.line.end() {
  read -r _ cols < <(stty size)
  printf '\x1b[%dG' "${cols}";
}
cursor.line.home() { printf '\x1b[1G'; }

cursor.linefeed() {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}E"
}

cursor.linebackfeed() {
  local amount=${1:-1}
  ! [[ ${amount} =~ ^[0-9]+$ ]] && amount=1
  printf "%b" "\x1b[${amount}F"
}

cursor.hide() { printf '\x1b[?25l'; }
cursor.show() { printf '\x1b[?25h'; }

term.size() { stty size; }

term.clear_line() { printf '\x1b[0G\x1b[0K'; }
term.clear_all() { printf '\x1b[0G\x1b[0J'; }
term.clear_screen() { printf '\x1b[0H\x1b[2J'; }

term.wrap.on() { printf '\x1b[?7h'; }
term.wrap.off() { printf '\x1b[?7l'; }

term.bold.on() { printf '\x1b[1m'; }
term.bold.off() { printf '\x1b[21m'; }
term.dimmed.on() { printf '\x1b[2m'; }
term.dimmed.off() { printf '\x1b[22m'; }
term.italic.on() { printf '\x1b[3m'; }
term.italic.off() { printf '\x1b[23m'; }
term.underlined.on() { printf '\x1b[4m'; }
term.underlined.off() { printf '\x1b[24m'; }
term.blink.on() { printf '\x1b[5m'; }
term.blink.off() { printf '\x1b[25m'; }
term.invert_color.on() { printf '\x1b[7m'; }
term.invert_color.off() { printf '\x1b[27m'; }
term.hidden.on() { printf '\x1b[8m'; }
term.hidden.off() { printf '\x1b[28m'; }
term.strikethrough.on() { printf '\x1b[9m'; }
term.strikethrough.off() { printf '\x1b[29m'; }

term.save() { printf '\e[?1049h'; }
term.back() { printf '\e[?1049l'; }
