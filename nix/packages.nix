{ pkgs }:

let
  common = with pkgs; [
    # Editors
    vim
    neovim

    # Core runtime/dependencies
    libsecret
    nodejs
    powershell

    # Cloud/provisioning
    awscli2
    (azure-cli.withExtensions (with azure-cli.extensions; [ virtual-network-manager ]))
    oci-cli
    terraform

    # CLI tools
    git
    git-credential-manager
    gh
    wget
    ripgrep
    fd
    fzf
    tree
    tree-sitter
    stow
    bind
    nmap
    usbutils
    parted
    unzip
    shellcheck
    nixfmt
    lazygit
    psmisc

    # Monitoring
    htop
    btop

    # Terminal
    fish
    starship
    tmux

    # Languages
    python3
    python3Packages.pip
    pipx
    rustc
    cargo

    # Neovim plugin build dependencies
    gcc
    gnumake

    # Neovim formatting
    shfmt

    # Language servers
    bash-language-server
    pyright
    yaml-language-server
    terraform-ls
    typescript
    typescript-language-server

    # Ansible
    ansible

    # Cluster
    kubectl
    kubeseal
    kubernetes-helm
    argocd

    # Quality of life
    kubectx
    k9s
  ];

  desktopOnly = with pkgs; [
    vscode
    gnome-keyring
    seahorse
    jq
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
