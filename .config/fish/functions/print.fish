#! /bin/env fish

# |>----|>----|>----|><-><|----<|----<|----<|
# |>      from Klapptnot's unix setup      <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

function print -d 'Rust style print with color formatting ability'
  set -f __format_str__ $argv[1]
  set -f args $argv[2..-1]
  # Replace all reset escape
  set __format_str__ (string replace -r --all '\{(0|r|rst)\}' '\x1b[0m' $__format_str__)
  # Replace all foreground color with the respective escape seq
  set __format_str__ (string replace -r --all '\{f([0-9]{1,3})\}' '\x1b[38;05;$1m' $__format_str__)
  # Replace all background color with the respective escape seq
  set __format_str__ (string replace -r --all '\{b([0-9]{1,3})\}' '\x1b[48;05;$1m' $__format_str__)

  set -f print_stack $__format_str__
  set -f i 1
  while true
    # Runs until there is no argument to consume
    # or fill until no placeholder is found
    not string match --regex '\{(?:(.)?([<\^>])?([0-9]*))?\}' $print_stack[$i] &>/dev/null; and break
    while set -l rematch (string match --regex '\{((.)?([<\^>])?([0-9]*))?\}' -- $print_stack[$i])
      test (count $args) -le 0; and set args[1] ""
      test (count $args) -le 0; and break
      set -l params $rematch[2]
      set -l l (string match --regex '[0-9]*$' -- $params)[1]; test -z $l && set l '0'
      set -l curr_len (string length -- $args[1])
      if test $rematch[1] = '{}'; or test $curr_len -ge $l
        set print_stack[$i] (string replace $rematch[1] -- $args[1] $print_stack[$i])
        set -e args[1]
        continue
      end
      set -l d (string match --regex '.?([<\^>])[0-9]*$' -- $params)[2]; test -z $d && set d '<'
      set -l c (string match --regex '(.)[<\^>][0-9]*$' -- $params)[2]; test -z $c && set c ' '
      switch $d
        case '<'
          set -l pr (string repeat -n (math $l - $curr_len) -- $c)
          set print_stack[$i] (string replace $rematch[1] -- $args[1]$pr $print_stack[$i])
          set -e args[1]
        case '>'
          set -l pl (string repeat -n (math $l - $curr_len) -- $c)
          set print_stack[$i] (string replace $rematch[1] -- $pl$args[1] $print_stack[$i])
          set -e args[1]
        case '^'
          set -l pb (math $l - $curr_len)
          set -l pl (string repeat -n (math -s 0 $pb / 2) -- $c)
          set -l pr (string repeat -n (math -s 0 $pb - (math -s 0 $pb / 2)) -- $c)
          set print_stack[$i] (string replace $rematch[1] -- "$pl$args[1]$pr" $print_stack[$i])
          set -e args[1]
      end
    end
    set print_stack[$i] (string replace -r --all '\\\\(\{|\})' '$1' -- $print_stack[$i])
    test (count $args) -gt 0 || break
    set -a print_stack $__format_str__
    set i (math $i + 1)
  end
  set print_stack[$i] (string replace --all "{}" "" -- $print_stack[$i])
  set print_stack[$i] (string replace --regex --all '\{(?:(.)?([<\^>])?([0-9]*))?\}' "" -- $print_stack[$i])
  set print_stack[$i] (string replace -r --all '\\\\(\{|\})' '$1' -- $print_stack[$i])
  set print_stack (string join '' -- $print_stack[1..-1])
  echo -en "$print_stack"
end

