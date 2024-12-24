#!/usr/bin/bash

# Usage:
#  str.esc_esc_seq <<< $'\033[38;5;12mHello World!\033[0m' # '\033[38;5;12mHello World!\033[0m'
function str.esc_esc_seq {
  # Remove ANSI escape sequences
  sed -E 's/\x1b/\\x1b/g'
}
