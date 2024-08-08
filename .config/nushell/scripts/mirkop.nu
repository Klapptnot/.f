# |>----|>----|>----|><-><|----<|----<|----<|
# |>     from Klapptnot's Shell setup      <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

# Simple, nice and customizable shell prompt

$env.mirko = ([$env.HOME, ".config", "mirkop.yaml"] | path join)

# Have a default config
if not ($env.mirko | path exists) {
  cp ([$nu.default-config-dir, "mirkop.yaml"] | path join) $env.mirko
}

# Contains strings, thresholds, colors, etc.
$env.mirko = ($env.mirko | open)

# GIT info colors
$env.mirko.color.git =   {
  i: (ansi $env.mirko.color.git.i)
  d: (ansi $env.mirko.color.git.d)
  a: (ansi $env.mirko.color.git.a),
  s: (ansi $env.mirko.color.git.s)
}

# Distinguish between a SSH connection and a local shell session
$env.mirko.str.from = (if ($env.SSH_TTY? | default nothing) == nothing { $env.mirko.str.from.base } else { $env.mirko.str.from.sshd })

# PATH_SHORTENING variables, last and short
$env.mirko.ldir = ""
$env.mirko.sdir = ""

# PROMPT_INDICATOR character for admin and normal user
$env.mirko.str.char = (if (is-admin) { $env.mirko.str.char.root } else { $env.mirko.str.char.else })
$env.mirko.str.char = $"(ansi --escape $env.mirko.color.normal)($env.mirko.str.char)(ansi reset)"

def path-shorten [path: string] -> string {
  let path_parts = ($path | split row (char path_sep))
  let parts_count = ($path_parts | length) - 1
  $path_parts | enumerate | each { |part|
    if $part.index == $parts_count {
        $part.item
    } else if ($part.item | str starts-with ".") {
        ($part.item | str substring 0..2)
    } else {
        ($part.item | str substring 0..1)
    }
  } | str join (char path_sep)
}

def get-path-color [path: path] {
  if ((which cksum).command?.0? == null) {
    return {
      fg: $env.mirko.color.dir
    }
  }
  let hex = (pwd | cksum | split row " ").0 | awk '{printf "%x", $1}' | fill --width 6 --character 0 | parse --regex '(?P<r>.{2})(?P<g>.{2})(?P<b>.{2})'
  let rgb = [
    $hex.r,
    $hex.g,
    $hex.b,
  ] | flatten

  return {
    fg: $"#($rgb | str join)"
  }
}

def git_status_info [path: path] {
  let changes = (git diff --shortstat e> $env.NULL_DEV | parse --regex "\\s*(?<f>[0-9]+)[^0-9]*(?<i>[0-9]+)[^0-9]*(?<d>[0-9]+)")
  let untracked = (git ls-files --other --exclude-standard $path e> $env.NULL_DEV | lines)
  let u_folders = ($untracked | each { $in | path dirname } | uniq | length)


  # Create an object with the calculated values
  {
    f: ($changes | get f.0? | default 0 | into int),
    i: ($changes | get i.0? | default 0 | into int),
    d: ($changes | get d.0? | default 0 | into int),
    u: ($untracked | length),
    U: $u_folders,
    b: (git branch --show-current e> $env.NULL_DEV)
  }
}

def do_collapse_ [] -> bool {
  $env.mirko.collapse > (term size).columns
}

def left_prompt_command_ [] {
  let dir = match (do --ignore-shell-errors { $env.PWD | path relative-to $nu.home-path }) {
    null => $env.PWD
    '' => '~'
    $relative_pwd => ([~ $relative_pwd] | path join)
  }

  $env.mirko.sdir = (if $env.mirko.ldir != $dir {
    path-shorten $dir
  } else {
    $env.mirko.sdir
  })

  $env.mirko.color.cdir = (if $env.mirko.ldir != $dir and $env.mirko.rdircolor {
    get-path-color $dir
  } else {
    $env.mirko.color.dir
  })
  $env.mirko.ldir = $dir

  let identity = ([
    (ansi --escape $env.mirko.color.user),
    ($env.mirko.str.user),
    (ansi --escape $env.mirko.color.from),
    ($env.mirko.str.from),
    (ansi --escape $env.mirko.color.host),
    ($env.mirko.str.host),
    (ansi --escape $env.mirko.color.normal),
    ":"
  ] | str join)

  $"($identity)(ansi --escape $env.mirko.color.cdir)($env.mirko.sdir)"
}

def right_prompt_command_ [] {
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

  let git_path = (git rev-parse --show-toplevel e> $env.NULL_DEV)
  let col = $env.mirko.color.git

  let git_info = match [(($git_path | str length) > 0), (do_collapse_)] {
    [true, true] => $"($col.a)(git branch --show-current)($col.s)",
    [true, false] => {
      let data = git_status_info $git_path
      $"($col.a)($data.f)($col.s)@($col.a)($data.b)($col.s) => ($col.i)+($col.a)($data.i)($col.s)/($col.d)-($col.a)($data.d) \(($data.u)($col.s)@($col.a)($data.U) ●\)"
    },
    _ => ""
  }

  # TODO: Check for SQL history
  let duration = " " + (history | last | get duration | into string | str replace --regex --all '([0-9]+)' $"(ansi plum1)${1}(ansi reset)")

  ([$git_info, $duration, $last_exit_code, (char space), $time_segment] | str join)
}

$env.PROMPT_COMMAND = { left_prompt_command_ }
$env.PROMPT_COMMAND_RIGHT = { right_prompt_command_ }
$env.PROMPT_INDICATOR = { $env.mirko.str.char }

$env.TRANSIENT_PROMPT_COMMAND = {|| "🚀 " }
$env.TRANSIENT_PROMPT_INDICATOR = {|| $env.mirko.str.char }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "⏎" }
