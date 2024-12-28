# |>----|>----|>----|><-><|----<|----<|----<|
# |>    from Klapptnot's Nushell config    <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

source ~/.config/nushell/scripts/functions.nu # Helper functions
source ~/.config/nushell/scripts/mirkop.nu    # Prompt functions
source ~/.config/nushell/scripts/goto.nu      # Alias based `cd`
source ~/.config/nushell/scripts/carapace.nu  # Completions helper

alias vi = vim
alias nano = vim
alias git = git --no-pager
alias systemctl = systemctl --no-pager

