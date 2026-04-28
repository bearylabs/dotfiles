# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, pkgs, ... }:

let
  emacs-overlay = import (
    builtins.fetchTarball {
      url = "https://github.com/nix-community/emacs-overlay/archive/87181272bf633bbc9f19a8aa8662833940bf18ed.tar.gz";
    }
  );
in
{
  imports = [
    # Include NixOS-WSL modules.
    <nixos-wsl/modules>
    <home-manager/nixos>
  ];

  wsl.enable = true;
  wsl.defaultUser = "hrudek";

  networking.hostName = "nixos-wsl";

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  console.keyMap = "de";

  users.users.hrudek = {
    isNormalUser = true;
    description = "Hendrik Rudek";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.fish;
  };

  home-manager.users.hrudek = {
    imports = [ ./home.nix ];
    home.file.".gitconfig.local".text = ''
      [user]
        name = hrudek
        email = hendrik.rudek@siempelkamp.com
      [credential]
        helper = store
        helper = /run/current-system/sw/bin/git-credential-manager
      [credential "https://dev.azure.com"]
        useHttpPath = true
    '';
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    emacs-overlay
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh.enable = false;
  programs.nix-ld.enable = true;

  services.openssh.enable = true;

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    # editors
    vim
    emacs

    # misc
    libsecret
    nodejs
    # cli tools
    git
    git-credential-manager
    gh
    wget
    ripgrep
    fd
    bind # nslookup
    nmap
    azure-cli
    gemini-cli
    codex
    github-copilot-cli
    claude-code
    ispell
    nixfmt
    lazygit
    psmisc

    # monitoring
    htop
    btop

    # terminal
    fish
    tmux

    # Language
    python3

    # Emacs dependencies
    emacsPackages.pbcopy
    emacsPackages.vterm
    libvterm
    libtool
    gcc
    glibc
    libcxx
    gdb
    cmake
    gnumake
    libgcc
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
