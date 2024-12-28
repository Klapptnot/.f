#!/usr/bin/bash

# bash does not support floating point numbers
# so use read to read the abs and the decimal part

function math.clamp {
  # max(m, min(v, M))
  IFS="." read -r m _ <<< "${1}"
  IFS="." read -r M _ <<< "${2}"
  IFS="." read -r v _ <<< "${3}"

  ((r = v < m ? m : v))
  ((r = r > M ? M : r))

  printf "%d" "${r}"
}

function math.round {
  # round(v)
  IFS="." read -r i d # read from stdin
  ((r = ${d:0:1} > 5 ? i + 1 : i))

  printf "%d" "${r}"
}

function math.sign {
  # sign(v)
  IFS="." read -r v _ # read from stdin

  ((r = v < 0 ? -1 : 1))

  printf "%d" "${r}"
}

function math.abs {
  # abs(v)
  IFS="." read -r i d # read from stdin
  ((r = i * (i < 0 ? -1 : 1)))

  printf "%d" "${r}"
}

function math.min {
  # min(a, b)
  IFS="." read -r a _ <<< "${1}"
  IFS="." read -r b _ <<< "${2}"

  ((r = a < b ? a : b))

  printf "%d" "${r}"
}

function math.max {
  # max(a, b)
  IFS="." read -r a _ <<< "${1}"
  IFS="." read -r b _ <<< "${2}"

  ((r = a > b ? a : b))

  printf "%d" "${r}"
}
