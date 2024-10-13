# |>----|>----|>----|><-><|----<|----<|----<|
# |>    from Klapptnot's nushell setup     <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

def get-aliased-paths [] -> table<alias: string[], expand: string[]> {
  let def = if (~/.config/dotf/goto.idx | path exists) {
    (open ~/.config/dotf/goto.idx | lines)
  } else {
    print $'(ansi yellow1)[WARN](ansi reset) Index file not found, default aliases are set'
    # Set a default config, but give a warning
    [
      '.c   &!HOME;/.config'
      'bin  /usr/bin'
      'lib  /usr/lib'
      'etc  /usr/etc'
      'dp   &!HOME;/Desktop'
      'nc   &*.c;/nvim'
    ]
  }
  $def | parse "{alias} {expand}" | str trim
}

def complete-aliases [] -> string[] {
  get-aliased-paths | get alias
}

# Small utility to go to folders by alias
export def --env gt [
  path?: string@complete-aliases,   # Alias (or path) to go to
  ...mods: string  # Modifiers for path or alias
  --list (-l),     # Display the aliases definitions
  --return (-r)    # Return the path instead of going to it
] -> string {

  let path = ($path | default $env.HOME)
  mut args = $mods
  let def = get-aliased-paths

  if $list {
    print $def
    return
  }

  if $path == "" {
    if $return {
      return $env.HOME
    }
    cd ($env.HOME)
    return
  }

  # Be like simple cd
  if ($path | path exists) {
    cd $path
    return
  }

  let aliases = ($def | each {|e| $e.alias})
  let ent_regex = '&(?P<opr>\*|!|%)(?P<val>[^;\s]*);'

  if $path not-in $aliases {
    print $'(ansi red1)[ERR ](ansi reset) Alias "($path)" not found'
    return
  }

  mut alias = ($def | where $it.alias == $path | get expand | get 0)

  while ($alias | find --regex $ent_regex) != null {
    let m = ($alias | parse --regex $ent_regex | get 0)
    match $m.opr {
      '*' => {
        if $m.val not-in $aliases {
          print $'(ansi red1)[ERR ](ansi reset) Alias "($m.val)" not found'
          return
        }
        let sal = ($def | where $it.alias == $m.val | get expand | get 0)
        $alias = ($alias | str replace $"&($m.opr)($m.val);" $sal)
      }
      '!' => {
        let envfi = ($env | get $m.val?)
        if $envfi == null {
          print $'(ansi red1)[ERR ](ansi reset) Environment variable "($m.val)" inaccessible'
          return
        }
        $alias = ($alias | str replace $"&($m.opr)($m.val);" $envfi)
      }
      '%' => {
        let index = ($m.val | into int) - 1
        if ($mods | length) <= $index {
          print $'(ansi red1)[ERR ](ansi reset) Parameter number "($m.val)" not found'
          return
        }
        $alias = ($alias | str replace $"&($m.opr)($m.val);" ($mods | get $index))
        $args = ($args | update $index nothing)
      }
    }
  }

  # Append every remaining item to path, only if it exists and is a folder
  while ($args | length) > 0 {
    if $args.0 != nothing {
      let newp = ([$alias, $args.0] | path join)
      if not ($newp | path exists) {
        break
      }
      $alias = $newp
    }
    $args = ($args | skip 1)
  }

  if not ($alias | path exists) {
    print $'(ansi red1)[ERR ](ansi reset) Folder "($alias)" does not exist or is not accessible'
    return
  }

  if $return {
    return $alias
  }
  cd $alias
}
