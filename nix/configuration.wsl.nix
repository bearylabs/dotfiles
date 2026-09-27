# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, pkgs, ... }:

let
  packages = import ./packages.nix { inherit pkgs; };
in
{
  imports = [
    # Include NixOS-WSL modules.
    <nixos-wsl/modules>
  ];

  wsl.enable = true;
  wsl.defaultUser = "hrudek";

  # GPU accel for WSLg (d3d12/mesa passthrough). Without this the i3/X11
  # session falls back to software rendering, causing laggy compositing
  # and sluggish input in the wslg window.
  hardware.graphics.enable = true;

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
    # WSL shells don't create a logind session, so /run/user/1000
    # (XDG_RUNTIME_DIR) is never made. Lingering creates it at boot.
    linger = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh.enable = false;
  programs.zoxide.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.nix-ld.enable = true;
  programs.openvpn3.enable = true;

  # WSLg's compositor supports neither ext-data-control nor wlr-data-control,
  # so Wayland clipboard clients fail. Push them onto XWayland, which WSLg
  # bridges to the Windows clipboard.
  environment.loginShellInit = "unset WAYLAND_DISPLAY";
  environment.interactiveShellInit = "unset WAYLAND_DISPLAY";
  # fish gets these via fenv, which propagates sets but not unsets, so it
  # needs the native equivalent.
  programs.fish.loginShellInit = "set -e WAYLAND_DISPLAY";
  programs.fish.interactiveShellInit = "set -e WAYLAND_DISPLAY";

  # Work machine: gh (and gh dash) target the corporate GHE instance when no
  # repo context implies a host.
  environment.sessionVariables.GH_HOST = "siempelkamp.ghe.com";

  # System-wide default editor (was falling back to nano).
  environment.variables.EDITOR = "vim";
  environment.variables.VISUAL = "vim";

  # NixOS-WSL manages /etc/resolv.conf via the WSL integration.
  networking.resolvconf.enable = false;

  services.openssh.enable = true;

  virtualisation.docker.enable = true;

  environment.systemPackages = packages.common;

  fonts = {
    packages = packages.fonts.common;
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "Inter" ];
        serif = [ "Inter" ];
        monospace = [
          "JetBrainsMono Nerd Font"
          "Symbols Nerd Font"
        ];
        emoji = [ "OpenMoji Color" ];
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
