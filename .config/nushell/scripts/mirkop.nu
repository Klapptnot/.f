# |>----|>----|>----|><-><|----<|----<|----<|
# |>     from Klapptnot's Shell setup      <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# Simple, nice and customizable shell prompt

def path-shorten [path: string] -> string {
  let path_parts = ($path | split row (char path_sep))
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

def get-path-fg-color [path: path] -> record<fg: string> {
  if ((which cksum).command?.0? == null) {
    return {
      fg: $env.mirko.color.dir
    }
  }
  let hex = (
    (pwd | cksum | split row " ").0
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

def git-status-info [path: path] -> record<f: int, i: int, d: int, u: int, U: int, b: string> {
  let changes = (git diff --shortstat | complete | get stdout | parse --regex '\s*(?<f>[0-9]+)[^0-9]*(?<i>[0-9]+)[^0-9]*(?<d>[0-9]+)')
  let untracked = (git ls-files --other --exclude-standard $path | complete | get stdout | lines)
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

def __left_prompt_command [] {
  let dir = match (do --ignore-shell-errors { $env.PWD | path relative-to $nu.home-path }) {
    null => $env.PWD
    '' => '~'
    $relative_pwd => ([~, $relative_pwd] | path join)
  }

  if $env.mirko.ldir != $dir {
    $env.mirko.sdir = (path-shorten $dir)
  }

  if $env.mirko.ldir != $dir and $env.mirko.rdircolor {
    $env.mirko.color.cdir = (get-path-fg-color $dir)
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

  $"($identity):(ansi --escape $env.mirko.color.cdir)($env.mirko.sdir)(ansi reset)"
}

def __right_prompt_command [] {
  # create a right prompt in grey with brigth grey separators and am/pm underlined
  let time_segment = ([
    (ansi reset)
    (ansi grey74)
    (date now | format date '%x %X') # try to respect user's locale
  ] | str join | str replace --regex --all "([/:])" $"(ansi grey85)${1}(ansi grey74)" |
    str replace --regex --all "([AP]M)" $"(ansi white_underline)${1}")

  let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {
    $"(ansi rb)[($env.LAST_EXIT_CODE)]"
  } else { "" }

  let git_path = (git rev-parse --show-toplevel | complete | get stdout)
  let col = $env.mirko.color.git

  let git_info = match [(($git_path | str length) > 0), ($env.mirko.collapse > (term size).columns)] {
    [true, true] => {
      let data = git-status-info $git_path
      $"($col.a)($data.f)($col.s)@($col.a)($data.b)($col.s) "         # <files>@<branch>
    },
    [true, false] => {
      let data = git-status-info $git_path
      [
        $"($col.a)($data.f)($col.s)@($col.a)($data.b)($col.s) =>",         # <files>@<branch>
        $" ($col.i)+($col.a)($data.i)($col.s)/($col.d)-($col.a)($data.d)", # +<additions>/-<deletions>
        $" \(● ($data.u)($col.s)@($col.a)($data.U)\) "                      # <untracked_files>@<untracked_folders>
      ] | str join
    },
    _ => ""
  }

  let duration = do {
    let duration = (history | last 1 | get duration | into string)
    if ($duration | length) > 0 {
      $duration | str replace --regex --all '([0-9]+)' $"(ansi plum1)${1}(ansi reset)"
    } else {
      ""
    }
  }

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
$env.mirko.ldir = ""
$env.mirko.sdir = ""

# PROMPT_INDICATOR character for admin|sudo and normal user
$env.mirko.str.char = (if (is-admin) { $env.mirko.str.char.root } else { $env.mirko.str.char.else })
$env.mirko.str.char = $"(ansi --escape $env.mirko.color.normal)($env.mirko.str.char)(ansi reset) "

$env.PROMPT_COMMAND = {|| __left_prompt_command }
$env.PROMPT_COMMAND_RIGHT = {|| __right_prompt_command }
$env.PROMPT_INDICATOR = {|| $env.mirko.str.char }

$env.TRANSIENT_PROMPT_COMMAND = {|| "󱓞 " }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "⏎" }
$env.TRANSIENT_PROMPT_INDICATOR = {|| $env.mirko.str.char }
