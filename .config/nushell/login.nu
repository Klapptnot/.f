if ("~/.config/.paths" | path exists) {
  let lns = (open --raw ~/.config/.paths | lines | str trim | path expand)

  for ln in $lns {
    if ($ln | str starts-with '#') {
      continue
    }
    if ($ln | str starts-with '@prepend ') {
      load-env { PATH: ($env.PATH | split row (char esep) | prepend ($ln | str substring 9.. | str trim)) }
    } else {
      load-env { PATH: ($env.PATH | split row (char esep) | append ($ln | str trim)) }
    }
  }
}

for kv in (open ~/.config/dotf/props.yaml | get shenv | transpose key val) {
  if ($kv.val | str starts-with '$ ') {
    load-env { $kv.key: (bash -c ($kv.val | str substring 2..)) }
  } else {
    load-env { $kv.key: $kv.val }
  }
}
