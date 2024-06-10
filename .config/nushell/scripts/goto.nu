# Small utility to go to folders by alias
export def --env gt [
  path?: string,   # Alias (or path) to go to
  ...mods: string  # Modifiers for path or alias
  --list (-l),     # Display the aliases definitions
  --return (-r)    # Return the path instead of going to it
] -> string {

  let path = ($path | default $env.HOME)
  mut mods = $mods

  let def = if ($"($env.HOME)/.config/goto.idx" | path exists) {
    (open $"($env.HOME)/.config/goto.idx" | lines)
  } else {
    print $'(ansi yellow1)[WARN](ansi reset) Index file not found, default aliases are set\n'
    # Set a default config, but give a warning
    [
      'cfg      &!HOME;/.config',
      'ubin     /usr/bin',
      'ulib     /usr/lib',
      'uetc     /usr/etc',
      'dtkp     &!HOME;/Desktop',
      'nvcfg    &*cfg;/nvim'
    ]
  }
  let def = ($def | parse "{alias} {expand}" | str trim)

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
    print $'(ansi red1)[ERR ](ansi reset) Alias "($path)" not found\n'
    return
  }

  mut alias = ($def | where $it.alias == $path | get expand | get 0)

  while ($alias | find --regex $ent_regex) != null {
    let m = ($alias | parse --regex $ent_regex) | get 0
    match $m.opr {
      '*' => {
        let sal = ($def | where $it.alias == $path | get expand | get 0)
        if $m.val not-in $aliases {
          print $'(ansi red1)[ERR ](ansi reset) Alias "($m.val)" not found\n'
          return
        }
        $alias = ($alias | str replace $"&($m.opr)($m.val);" $sal)
      }
      '!' => {
        let envfi = ($env | get $m.val?)
        if $envfi == null {
          print $'(ansi red1)[ERR ](ansi reset) Environment variable "($m.val)" inaccessible\n'
          return
        }
        $alias = ($alias | str replace $"&($m.opr)($m.val);" $envfi)
      }
      '%' => {
        if ($mods | length) > ($m.val | into int) {
          $alias = ($alias | str replace $"&($m.opr)($m.val);" ($mods | get $m.val |into int))
          $mods = ($mods | drop 1)
        } else {
          print $'(ansi red1)[ERR ](ansi reset) Modifiers number "($m.val)" not found\n'
          return
        }
      }
    }
  }

  # Append every remaining item to path, only if it exists and is a folder
  while ($mods | length) > 0 {
    let newp = ([$alias, $mods.0] | path join)
    if not ($newp | path exists) {
      break
    }
    $alias = $newp
    $mods = ($mods | skip 1)
  }

  if not ($alias | path exists) {
    print $'(ansi red1)[ERR ](ansi reset) Folder "($alias)" does not exist or is not accessible\n'
    return
  }

  if $return {
    return $alias
  }
  cd $alias
}
