#! /bin/env fish

# |>----|>----|>----|><-><|----<|----<|----<|
# |>     from Klapptnot's Termux setup     <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# Completions for goto utility
# ~/.config/fish/completions/goto.fish

# Read aliased from config file and add them to completions with flags
# on completion request when there is no alias on commandline
# preventing aliases from
function __fish_goto_opt_alias
  print "{}\n" (grep -Po '^\s*\K[^\s]+' ~/.config/dotf/goto.idx) -h -l -p --help --list --print
end

# Uses current commandline info to add child folders to the completions
# on completion request when already found an alias in commandline
function __fish_goto_show_path
  set -f cmdl (string replace --regex '^goto' 'goto --print' (commandline))
  set -f f (eval $cmdl)
  if test -d $f
    find $f -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
  end
end

# Parse and set as completions all aliases names from config file
# on completion request when there are no flags or aliases
function __fish_goto_list_aliases
  set -f aliases (grep -Po '^\s*\K[^\s]+' ~/.config/dotf/goto.idx)
  for alias in $aliases
    echo $alias
  end
end


# Show flags and aliases if not one found already
complete -c goto -f -a '(__fish_goto_list_aliases)' -d 'Alias' -n 'not __fish_seen_subcommand_from (__fish_goto_opt_alias)'
# Show children folders from expanded alias when alias is found and completion is requested
complete -c goto -f -a '(__fish_goto_show_path)' -d 'Child folder' -n '__fish_seen_subcommand_from (__fish_goto_list_aliases)'

