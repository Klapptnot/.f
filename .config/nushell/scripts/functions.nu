def __open_nvim_fzf_file [] {
  let f = (
    FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git' fzf
    --prompt 'File: ' --pointer '=>' --marker '==' -m
    --preview-window '65%' --preview-label 'Preview'
    --preview 'bat {}'
  )
  if $f != '' { nvim $f }
}
