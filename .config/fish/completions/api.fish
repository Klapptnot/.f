#!/usr/bin/env fish
# |>----|>----|>----|><-><|----<|----<|----<|
# |>     from Klapptnot's Termux setup     <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# A wrapper for termux-api (Completions)
# ~/.config/fish/completions/api.fish

# Function to get the list of services
function __fish_api_services
  echo ~/../usr/bin/termux-* | grep -oP '(?<=termux-)[^\s]*'
end

# Completion function for the 'api' command
complete -c api -a '(__fish_api_services)' -d 'Service' -n 'not __fish_seen_subcommand_from (__fish_api_services)'

