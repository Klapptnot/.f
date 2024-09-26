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

function __fzf_nvim_open_file {
  local file
  if file=$(fzf_get_file); then
    nvim "${file}"
  fi
}

function __fzf_cat_file {
  local file
  if file=$(__fzf_open_file_nvim); then
    gfc "${file}" "${@}"
  fi
}

function print_path() {
  for p in ${PATH//:/\ }; do
    printf '%s\n' "${p}"
  done
}
