#! /bin/env bash
# shellcheck disable=SC2034

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Break execution
  printf "[\x1b[38;05;160m*\x1b[00m] This script is not made to run as a normal script\n"
  exit 1
fi

pacman_pkgs=(
  base
  base-devel
  bat
  blueman
  bluez-utils
  brightnessctl
  cliphist
  efibootmgr
  fastfetch
  fd
  flatpak
  fzf
  git
  github-cli
  gnome-control-center
  gnome-settings-daemon
  grim
  gucharmap
  htop
  hypridle
  hyprland
  hyprlock
  hyprpaper
  jq
  kitty
  loupe
  neovim
  nodejs
  npm
  ntfs-3g
  nushell
  papirus-icon-theme
  python-pip
  python-pipx
  rofi-wayland
  slurp
  swaync
  thunar
  ttf-cascadia-code-nerd
  ttf-joypixels
  tumbler
  vivid
  vlc
  waybar
  wget
  yad
  zip
)

yay_pkgs=(
  carapace-bin
  catppuccin-gtk-theme-mocha
  hyprpicker
  wlogout
)

nfolders=(
  "${HOME}/.cache/hyprland"
  "${HOME}/.cache/carapace"
)

function post_install {
  [ -e "${HOME}/.geoinfo" ] || {
    [ -z "${USER_GEOINFO}" ] && log w "No geographic info given, leaving empty"
    echo "${USER_GEOINFO}" > "${HOME}/.geoinfo"
  }
  CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' carapace _carapace nushell > ~/.cache/carapace/init.nu
  bat cache --build &>/dev/null
}

function gen_ignore_list {
  ignore=(
    "README.md"
    "dotf"
    ".conf.sh"
    "misc*"
    ".git*"
    ".config/nushell/history*"
  )

  [ -n "${TERMUX_VERSION@A}" ]    || ignore+=(".termux*")
  # Desktop environment
  command -v Hyprland > /dev/null || ignore+=(".config/hypr*")
  command -v rofi > /dev/null     || ignore+=(".config/rofi*")
  command -v swaync > /dev/null   || ignore+=(".config/swaync*")
  command -v waybar > /dev/null   || ignore+=(".config/waybar*")
  command -v wlogout > /dev/null  || ignore+=(".config/wlogout*")
  command -v kitty > /dev/null    || ignore+=(".config/kitty*")
  # Shell
  command -v nu > /dev/null    || ignore+=(".config/nushell*")
  command -v fish > /dev/null  || ignore+=(".config/fish*")
  command -v zsh > /dev/null   || ignore+=(".zshrc")
  command -v bat > /dev/null   || ignore+=(".config/bat*")
}
