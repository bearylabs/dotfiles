{ pkgs }:

let
  common = with pkgs; [
    # Editors and portable developer tools are managed by mise. Keep vim as a
    # recovery editor that is always available, even before `mise install`.
    vim

    # Core runtime/dependencies
    libsecret
    mise

    # CLI tools
    git
    git-credential-manager
    gnupg
    pass
    pinentry-curses
    # Used by desktop processes such as Polybar, which do not inherit the
    # interactive shell environment activated by mise.
    jq
    # mise uses the existing gh login to authenticate GitHub downloads, so gh
    # must be available before mise installs its own tool set.
    gh
    wget
    tree
    stow
    bind
    nmap
    usbutils
    parted
    unzip
    nixfmt
    psmisc

    # Monitoring
    htop

    # Terminal
    fish
    tmux

    # Neovim plugin build dependencies
    gcc
    gnumake

  ];

  desktopOnly = with pkgs; [
    vscode
    gnome-keyring
    seahorse
    virtio-win
    kitty
    ghostty

    # Desktop
    solaar
    flameshot
    brightnessctl
    networkmanagerapplet
    pavucontrol
    rofi
    (polybar.override {
      i3Support = true;
      pulseSupport = true;
    })
    feh
    xss-lock
    xidlehook
    xset
    xclip
    dunst
    libnotify
    google-chrome
    obsidian
    rpi-imager
    mediawriter
    prusa-slicer
    thunderbird
  ];

in
{
  inherit common;
  desktop = desktopOnly;

  fonts = {
    common = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
    desktopOnly = with pkgs; [
      inter
      openmoji-color
    ];
  };

}
