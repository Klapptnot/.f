def __open_nvim_fzf_file [] {
  let f = (
    fzf
    --prompt 'File: '
    --preview-window '65%' --preview-label 'Preview'
    --preview 'bat {}' | complete
  )
  if $f.stdout != '' { nvim ($f.stdout | str trim) }
}
