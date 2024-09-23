#! /bin/env bash

function fzf_get_file {
  local file
  file=$(
    fzf --prompt 'File: ' --pointer '=>' --marker '==' \
      --preview-window '65%' --preview-label 'Preview' \
      --preview='bat {}'
  )
  if ! [ -f "${file}" ]; then
    return 1
  fi
  printf '%s' "${file}"
}

function fnvim {
  local file
  if file=$(fzf_get_file); then
    nvim "${file}"
  fi
}

function fgfc {
  local file
  if file=$(fzf_get_file); then
    gfc "${file}" "${@}"
  fi
}

function print_path() {
  for p in ${PATH//:/\ }; do
    printf '%s\n' "${p}"
  done
}
