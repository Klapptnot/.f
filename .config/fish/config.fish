if [ $__fish_init_user_env_var = 1 ]
  set -gx RUST_BACKTRACE full
  set -gx FZF_DEFAULT_OPTS '--color=fg:#d0d0d0,bg:,hl:#7143e6 --color=fg+:#d0d0d0,bg+:#262626,hl+:#00f2ff --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'
  set -gx MICRO_TRUECOLOR 1
  set -gx COLORTERM truecolor
  set -gx UTILS ~/repos/utils
  fish_add_path "~/bin" "$UTILS/bin" "~/.local/bin" "~/.cargo/bin"
  set -gx MICROSD /storage/06B6-1CF8
  set -gx L3MON https://open.spotify.com/playlist/4FmJwjqqdgpLXc0ZDcadJ4
  set -gx MXM_COOKIES "mxm_bab=AB; musixmatchUserGuid=7a09ec66-8928-43ed-981a-97296d33e581; captcha_id=%2FxhVAVOL%2B4QZHJsI418O8AXJPj7hbmvcO0rKy3X6tg0Pt3pEtJeGTJn9OpJq4L16mKGKiWuUlAXCiAQHFNIeigas0KMXAUvtjGzZMRFoeQFvLk41P3a45nYo2GVQloYw; x-mxm-user-id=undefined; x-mxm-token-guid=undefined; mxm-encrypted-token=; translate_lang=%7B%22key%22%3A%22en%22%2C%22name%22%3A%22English%22%7D"
end

# set -U fish_history_histcontrol 'ignorespace'

function fzf_get_file -d "Use fzf to get a file"
  if set -l file (
      fzf --prompt 'File: ' --pointer '=>' --marker '=='\
        --preview-window '65%' --preview-label 'Preview'\
        --preview='bat --paging never --wrap character --number --color always --italic-text always --line-range :250 {}' $pwd
    )
    printf $file
  else
    return 1
  end
end

function fuzzy_nvim -d "Open a file searched by fzf with nvim"
  if set -l file (fzf_get_file)
    nvim "$file"
    commandline -f repaint
  end
end

function fuzzy_bat -d "Print the content of a file searched by fzf"
  if set -l file (fzf_get_file)
    printf '\n'
    bat "$file"
    commandline -f repaint
  end
end

function __fish_goto_wrapper -d 'Gets the path and goes to it'
  cd (goto $argv)
end

# `cd` with alias support (fish function)
function gt --wraps goto --description 'alias gt=goto'
  goto $argv
end

bind \co fuzzy_nvim
bind \cu fuzzy_bat
bind \cl 'clear; commandline -f repaint'

if status is-interactive
  # Commands to run in interactive sessions can go here
end
