#! /bin/env bash

function str.rgb2hex {
  # Accept 'rgb(244,23,90)' color
  # local rgb="${1:4}" && rgb="${rgb%?}"
  : "$(< /dev/stdin)"
  local rgb="${_:4:${#_}-2}"
  # This works as long as printf will print the result
  # instead of just exiting with a stderr message
  # shellcheck disable=SC2086
  printf '#%02x%02x%02x' ${rgb//,/\ } 2> /dev/null
  return 0 # Mask the return status code (printf will return > 0)
}
