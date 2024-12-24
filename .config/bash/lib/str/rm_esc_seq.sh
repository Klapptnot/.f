#!/usr/bin/bash

# Usage:
#  str.rm_esc_seq <<< $'\033[38;5;12mHellow\033[0GHello World!\033[0m' # 'Hello World'
function str.rm_esc_seq {
  # Remove ANSI escape sequences
  sed -E '
    s/^.*\x1b\[0?[kK]//g;s/^.*\x1b\[0?[gG]//g; # Remove overwritten/cleaned lines
    s/\x1b\[([0-9]*;)*[A-Za-z]//g;             # Basic ANSI sequences
    s/\x1b\[[\(\)#?]?([0-9];?)*[A-Za-z]//g;    # Extended ANSI sequences
    s/\x1b[@-_][0-9;]*[0-9A-Za-z]*//g;         # Any unhandled sequences
  '
}
