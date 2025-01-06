# |>----|>----|>----|><-><|----<|----<|----<|
# |>     from Klapptnot's Shell setup      <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# Simple, nice and customizable shell prompt

def path-shorten []: string -> string {
  let path_parts = ($in | split row (char path_sep))
  let parts_count = ($path_parts | length) - 1
  $path_parts | enumerate | each { |part|
    if $part.index == $parts_count {
        $part.item
    } else if ($part.item | str starts-with ".") {
        ($part.item | str substring 0..1)
    } else {
        ($part.item | str substring 0..0)
    }
  } | str join (char path_sep)
}

def get-path-fg-color []: string -> record<fg: string> {
  if ((which cksum).command?.0? == null) or $env.mirko.rdircolor != true {
    return $env.mirko.color.dir
  }
  let hex = (
    ($in | cksum | split row " ").0
    | awk '{printf "%x", $1}'
    | fill --width 6 --character 0
    | parse --regex '(?P<r>.{2})(?P<g>.{2})(?P<b>.{2})'
  )
  let rgb = ([
    "#",
    $hex.r,
    $hex.g,
    $hex.b,
  ] | flatten | str join)

  return {
    fg: $rgb
  }
}

def get-last-command-duration []: nothing -> string {
  let duration = (
    history | last 1
      | get duration.0
      | into string
  )
  if ($duration | str length) > 0 {
    $duration | str replace --regex --all '([0-9]+)' $"(ansi plum1)${1}(ansi reset)"
  } else {
    ""
  }
}

def git-status-info []: nothing -> record<f: int, i: int, d: int, u: int, U: int, b: string> {
  let changes = (git diff --shortstat | complete | get stdout | parse --regex '\s*(?<f>[0-9]+)[^0-9]*(?<i>[0-9]+)[^0-9]*(?<d>[0-9]+)')
  let untracked = (git ls-files --other --exclude-standard | complete | get stdout | lines)
  let u_folders = ($untracked | each { $in | path dirname } | uniq | length)


  # Create a record with the calculated values
  {
    f: ($changes | get f.0? | default 0 | into int),
    i: ($changes | get i.0? | default 0 | into int),
    d: ($changes | get d.0? | default 0 | into int),
    u: ($untracked | length),
    U: $u_folders,
    b: (git branch --show-current | complete | get stdout | str trim)
  }
}

def __left_prompt_command [--transient]: nothing -> string {
  let dir = match (do --ignore-errors { $env.PWD | path relative-to $nu.home-path }) {
    null => $env.PWD
    '' => '~'
    $relative_pwd => ([~, $relative_pwd] | path join)
  }

  if $env.mirkov.ldir != $dir {
    $env.mirkov.sdir = ($dir | path-shorten)
  }

  if $env.mirkov.ldir != $dir {
    $env.mirkov.cdir = ($dir | get-path-fg-color)
  }
  if $transient {
    return $"(ansi --escape $env.mirkov.cdir)($env.mirkov.sdir)(ansi reset):"
  }

  # Save last dir for next call
  $env.mirko.ldir = $dir

  let identity = ([
    (ansi --escape $env.mirko.color.user),
    ($env.mirko.str.user),
    (ansi --escape $env.mirko.color.from),
    ($env.mirko.str.from),
    (ansi --escape $env.mirko.color.host),
    ($env.mirko.str.host),
    (ansi --escape $env.mirko.color.normal)
  ] | str join)

  $"($identity):(ansi --escape $env.mirkov.cdir)($env.mirkov.sdir)(ansi reset)"
}

def __right_prompt_command [--transient]: nothing -> string {
  # create a right prompt in grey with brigth grey separators and am/pm underlined
  let time_segment = (
    $"(ansi reset)(ansi grey74)(date now | format date '%X')" # try to respect user's locale
      | str replace --regex --all "([/:])" $"(ansi grey85)${1}(ansi grey74)"
      | str replace --regex --all "([AP]M)" $"(ansi white_underline)${1}(ansi reset)"
  )

  if $transient {
    return $"(ansi --escape $env.mirko.color.normal)($time_segment)(ansi reset)"
  }

  let last_exit_code = if ($env.LAST_EXIT_CODE != 0) { $" (ansi rb)[($env.LAST_EXIT_CODE)]" } else { "" }
  let is_git_repo = ((git rev-parse --show-toplevel | complete | get exit_code) == 0)
  let col = $env.mirko.color.git
  let should_collapse = ($env.mirko.collapse > (term size).columns)

  let git_info = match [($is_git_repo), ($should_collapse)] {
    [true, true] => {
      let data = (git-status-info)
      $"($col.a)($data.f)($col.s)@($col.a)($data.b)($col.s)(ansi reset) "         # <files>@<branch>
    },
    [true, false] => {
      let data = (git-status-info)
      [
        $"($col.a)($data.f)($col.s)@($col.a)($data.b)($col.s)",     # <files>@<branch>
        $" ($col.i)+($data.i)($col.s)/($col.d)-($data.d)($col.a)",  # +<additions>/-<deletions>
        $" \(● ($data.u)($col.s)@($col.a)($data.U)\)(ansi reset) "  # <untracked_files>@<untracked_folders>
      ] | str join
    },
    _ => ""
  }

  let duration = get-last-command-duration

  ([$git_info, $duration, $last_exit_code, " ", $time_segment] | str join)
}

# Initialize config file
let mirko_path = ([$env.HOME, ".config", "mirkop.yaml"] | path join)

if not ($mirko_path | path exists) {
  open ([$nu.default-config-dir, "mirkop.yaml"] | path join) |
    update str.user $env.USER |
    update str.host (uname).nodename |
    to yaml | save -f $mirko_path
}

$env.mirko = ($mirko_path | open)

# Set up git colors
$env.mirko.color.git =   {
  i: (ansi $env.mirko.color.git.i) # Insertion
  d: (ansi $env.mirko.color.git.d) # Deletion
  a: (ansi $env.mirko.color.git.a) # Anything
  s: (ansi $env.mirko.color.git.s) # Separators
}

# Distinguish between a SSH connection and a local shell session
$env.mirko.str.from = (if ($env.SSH_TTY? | default nothing) == nothing { $env.mirko.str.from.base } else { $env.mirko.str.from.sshd })

# PWD shortening variables, last short path and short
$env.mirkov = {
  ldir: "",
  sdir: "",
  cdir: ""
}

# PROMPT_INDICATOR character for admin|sudo and normal user
$env.mirko.str.char = (if (is-admin) { $env.mirko.str.char.root } else { $env.mirko.str.char.else })
$env.mirko.str.char = $"(ansi --escape $env.mirko.color.normal)($env.mirko.str.char)(ansi reset) "

$env.PROMPT_COMMAND = {|| __left_prompt_command }
$env.PROMPT_COMMAND_RIGHT = {|| __right_prompt_command }
$env.PROMPT_INDICATOR = {|| $env.mirko.str.char }

if $env.mirko.transient == true {
  $env.TRANSIENT_PROMPT_COMMAND = {|| __left_prompt_command --transient }
  $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| __right_prompt_command --transient }
  $env.TRANSIENT_PROMPT_INDICATOR = {|| $env.mirko.str.char }
}
