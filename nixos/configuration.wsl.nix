# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, pkgs, ... }:

let
  unstable =
    import (builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz")
      {
        config = config.nixpkgs.config;
      };

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
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };

  home-manager.users.hrudek = import ./home.nix;

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

  environment.systemPackages = with pkgs; [
    # editors
    vim
    unstable.vscode
    emacs

    # shells and terminal tools
    fish
    tmux

    # core CLI tools
    git
    gh
    wget
    curl
    ripgrep
    fd
    unzip
    zip
    gnutar
    gzip
    xz
    gnupg
    rsync
    just

    # networking and diagnostics
    bind
    nmap
    openssh

    # coding/runtime tools
    nodejs
    python3
    gcc
    gdb
    cmake
    gnumake
    nil
    nixfmt

    # monitoring
    htop
    btop
    psmisc

    # AI / developer CLIs
    unstable.gemini-cli
    unstable.codex
    unstable.github-copilot-cli

    # Emacs dependencies
    ispell
    emacsPackages.pbcopy
    emacsPackages.vterm
    libvterm
    libtool
    glibc
    libcxx
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
