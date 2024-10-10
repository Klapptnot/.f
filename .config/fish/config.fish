# |>----|>----|>----|><-><|----<|----<|----<|
# |>      from Klapptnot's unix setup      <|
# |>   https://github.com/Klapptnot/dotf   <|
# |>----|>----|>----|><-><|----<|----<|----<|

if [ $__fish_init_user_env_var = 1 ]
  set -gx RUST_BACKTRACE full
  set -gx FZF_DEFAULT_OPTS '--color=fg:#d0d0d0,bg:,hl:#7143e6 --color=fg+:#d0d0d0,bg+:#262626,hl+:#00f2ff --color=info:#afaf87,prompt:#d7005f,pointer:#af5fff --color=marker:#87ff00,spinner:#af5fff,header:#87afaf'
  set -gx COLORTERM truecolor
end

function _r_fzf_get_file -d "Use fzf to get a file"
  if set -l file (
      fzf --prompt 'File: ' --pointer '>' --marker '='\
        --preview-window '65%' --preview-label 'Preview'\
        --preview='bat {}' $pwd
    )
    printf $file
  else
    return 1
  end
end

function __fzf_nvim_open_file -d "Open a file searched by fzf with nvim"
  if set -l file (_r_fzf_get_file)
    nvim "$file"
    commandline -f repaint
  end
end

function __fzf_cat_file -d "Print the content of a file searched by fzf"
  if set -l file (_r_fzf_get_file)
    printf '\n'
    bat "$file"
    commandline -f repaint
  end
end

# `cd` with alias support (fish function)
function gt --wraps goto --description 'alias gt=goto'
  goto $argv
end

function bash_yq --description 'Use bash simple yq alternative'
  bash ~/.config/bash/lib/yq.sh $argv
end

bind \co __fzf_nvim_open_file
bind \cu __fzf_cat_file
bind \cl 'clear; commandline -f repaint'

set fish_prompt_cfgf ~/.config/mirkop.yaml

set fish_prompt_user (bash_yq .str.user $fish_prompt_cfgf || echo $USER)
set fish_prompt_host (bash_yq .str.host $fish_prompt_cfgf || echo $hostname)
set fish_prompt_rdircolor (bash_yq .rdircolor $fish_prompt_cfgf || echo true)
if fish_is_root_user
  set fish_prompt_delim (bash_yq .str.char.root $fish_prompt_cfgf || echo '#')
else
  set fish_prompt_delim (bash_yq .str.char.else $fish_prompt_cfgf || echo '>')
end
# If we don't have unicode use a simpler delimiter
if not string match -qi "*.utf-8" -- $LANG $LC_CTYPE $LC_ALL
  fish_is_root_user; and set fish_prompt_delim "#"; or set fish_prompt_delim ">"
end

if status is-interactive
  # Commands to run in interactive sessions can go here
end
