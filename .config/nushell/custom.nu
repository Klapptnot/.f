# |>----|>----|>----|><-><|----<|----<|----<|
# |>    from Klapptnot's Nushell config    <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

use std

$env.NULL_DEV = (std null-device)
$env.FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git0 -l -g ""'
$env.LS_COLORS = (vivid generate 'catppuccin-mocha' | str trim)
$env.UTILS = ([$env.HOME, "repos", "utils"] | path join)

$env.PATH = [
  $env.PATH,
  ([$env.HOME, ".cargo", "bin"] | path join),
  ([$env.HOME, ".local", "bin"] | path join),
  ([$env.HOME, "bin"] | path join),
  ([$env.HOME, "repos", "utils", "bin"] | path join),
  ([$nu.default-config-dir, "bin"] | path join),
]

source mirkop.nu
source goto.nu
