use std

$env.NULL_DEV = (std null-device)

$env.LS_COLORS = (vivid generate 'catppuccin-mocha' | str trim)

$env.UTILS = ([$env.HOME, "repos", "utils"] | path join)
$env.PATH = [
  $env.PATH,
  ([$env.HOME, "bin"] | path join),
  ([$env.HOME, "repos", "utils", "bin"] | path join),
  ([$nu.default-config-dir, "bin"] | path join),
]
# $env.PATH = ($env.PATH | uniq)

$env.prompt = {
  rdircolor: true,
  indicator: (if (is-admin) { $"(char elevated) " } else { "► " })
  ldir: nothing.
  sdir: nothing
}

$env.prompt.str = {
  user: "klapptnot",
  host: "zircon",
  at  : (match ($env.SSH_TTY? | default nothing) {
    nothing => " at ",
    _ => " in "
  })
}

$env.prompt.color = {
  host:   {
    fg: "#9b5ced"
  },
  user:   {
    fg: "#bd93f9"
  },
  error:  {
    fg: "#de4b4b"
  }
  dir:    {
    fg: "#e8e8e8"
  }
  normal: {
    fg: "#e8e8e8"
  }
  at:     {
    fg: "#e8e8e8"
  }
  git:    {
    i: (ansi seagreen1b)
    d: (ansi red1)
    a: (ansi lightcyan1),
    s: (ansi def)
  }
}

$env.prompt.indicator = $"(ansi --escape $env.prompt.color.normal)($env.prompt.indicator)(ansi reset)"

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
      fg: $env.prompt.color.dir
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

def left_prompt_command_ [] {
  let dir = match (do --ignore-shell-errors { $env.PWD | path relative-to $nu.home-path }) {
    null => $env.PWD
    '' => '~'
    $relative_pwd => ([~ $relative_pwd] | path join)
  }

  $env.prompt.sdir = (if $env.prompt.ldir != $dir {
    path-shorten $dir
  } else {
    $env.prompt.sdir
  })

  $env.prompt.color.cdir = (if $env.prompt.ldir != $dir and $env.prompt.rdircolor {
    get-path-color $dir
  } else {
    $env.prompt.color.dir
  })
  $env.prompt.ldir = $dir

  let identity = ([
    (ansi --escape $env.prompt.color.user),
    ($env.prompt.str.user),
    (ansi --escape $env.prompt.color.at),
    ($env.prompt.str.at),
    (ansi --escape $env.prompt.color.host),
    ($env.prompt.str.host),
    (ansi --escape $env.prompt.color.normal),
    ":"
  ] | str join)

  $"($identity)(ansi --escape $env.prompt.color.cdir)($env.prompt.sdir)"
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

  let git_info = (if ($git_path | str length) > 0 {
    let col = $env.prompt.color.git
    let data = git_status_info $git_path
    $"($col.a)($data.f)($col.s)@($col.a)($data.b)($col.s) => ($col.i)+($col.a)($data.i)($col.s)/($col.d)-($col.a)($data.d) \(($data.u)($col.s)@($col.a)($data.U) ●\)(ansi reset)"
  } else {
    ""
  })

  # TODO: Check for SQL history
  let duration = " " + (history | last | get duration | into string | str replace --regex --all '([0-9]+)' $"(ansi plum1)${1}(ansi reset)")

  ([$git_info, $duration, $last_exit_code, (char space), $time_segment] | str join)
}

$env.PROMPT_COMMAND = { left_prompt_command_ }
$env.PROMPT_COMMAND_RIGHT = { right_prompt_command_ }
$env.PROMPT_INDICATOR = { $env.prompt.indicator }

$env.TRANSIENT_PROMPT_COMMAND = {|| "🚀 " }
$env.TRANSIENT_PROMPT_INDICATOR = {|| $env.prompt.indicator }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "⏎" }

source goto.nu
