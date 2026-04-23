# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstable =
    import (builtins.fetchTarball "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz")
      {
        config = config.nixpkgs.config;
      };
  zen-browser =
    import (builtins.fetchTarball "https://github.com/youwen5/zen-browser-flake/archive/master.tar.gz")
      {
        inherit pkgs;
      };
  emacs-overlay = import (
    builtins.fetchTarball {
      url = "https://github.com/nix-community/emacs-overlay/archive/87181272bf633bbc9f19a8aa8662833940bf18ed.tar.gz";
    }
  );
in

{

  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
    <home-manager/nixos>
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
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

  # GDM still relies on the X server stack even when launching Wayland sessions.
  services.xserver.enable = true;

  # Use GDM for session selection and prefer Sway as the default session.
  services.displayManager.gdm.enable = true;
  # Keep a GUI desktop available in GDM as a fallback desktop session.
  services.desktopManager.gnome.enable = true;

  # Enable Sway.
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # Wayland portal setup for wlroots/Sway sessions.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  # Make sure the greeter can see and prefer the Sway session explicitly.
  services.displayManager = {
    defaultSession = "sway";
    sessionPackages = [ config.programs.sway.package ];
  };

  # Enables Gnome Keyring to store secrets for applications.
  services.gnome.gnome-keyring.enable = true;

  # Required for rpi-imager: allows read/write access to storage devices
  services.udisks2.enable = true;

  # Required for privilege escalation prompts in graphical applications.
  security.polkit.enable = true;

  # Preserve Wayland environment variables when escalating with sudo.
  security.sudo.extraConfig = ''
    Defaults env_keep = "DISPLAY WAYLAND_DISPLAY XDG_SESSION_TYPE QT_QPA_PLATFORM"
  '';

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.logind = {
    lidSwitch = "suspend";
    # Keep the machine from running in a bag when plugged in and lid is closed.
    lidSwitchExternalPower = "suspend";
    settings.Login = {
      IdleAction = "suspend";
      # Keep suspend after the sway display timeout so AC power can blank the
      # display at 10 minutes before the system sleeps.
      IdleActionSec = "15min";
    };
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  services.tailscale = {
    enable = true;
    # Enable tailscale at startup

    # If you would like to use a preauthorized key
    #authKeyFile = "/run/secrets/tailscale_key";
  };

  # Tune CPU behavior based on power source.
  services.auto-cpufreq = {
    enable = true;
    settings = {
      # Keep battery mode cool and conservative.
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      # Use full CPU performance when plugged in.
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # Avoid competing CPU power-policy managers; auto-cpufreq handles this.
  services.power-profiles-daemon.enable = false;

  # Enable the kernel power-management hooks used by NixOS power options.
  powerManagement.enable = true;

  # Apply PowerTOP tunables at boot for extra power savings.
  powerManagement.powertop.enable = true;

  # Let the firmware/OS react to thermal pressure and prevent overheating.
  services.thermald.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.hrudek = {
    isNormalUser = true;
    description = "Hendrik Rudek";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      thunderbird
    ];
    # Use zsh as the default login shell
    shell = pkgs.fish;
  };
  home-manager.users.hrudek = import ./home.nix;

  # Install firefox.
  programs.firefox.enable = true;

  # Enable the local file sharing application.
  programs.localsend.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    emacs-overlay
  ];

  # Enable modern nix CLI + flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Enable zsh and some common modules (completions, etc.)
  programs.zsh.enable = true;
  programs.zsh.ohMyZsh.enable = false; # optional, disable if you prefer manual config

  # Enable fish shell
  programs.fish.enable = true;
  programs.dconf.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libsecret
    glib
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # editors
    vim
    unstable.vscode
    emacs

    # misc
    libsecret
    gnome-keyring
    seahorse
    nodejs
    # cli tools
    git
    gh
    wget
    ripgrep
    fd
    bind # nslookup
    nmap
    usbutils
    unstable.gemini-cli
    unstable.codex
    unstable.github-copilot-cli
    unstable.claude-code
    ispell
    nixfmt
    lazygit
    parted
    psmisc

    # monitoring
    htop
    btop

    # terminal
    fish
    kitty
    ghostty
    tmux

    # Language
    python3

    # desktop
    flameshot
    brightnessctl
    networkmanagerapplet
    pavucontrol
    wofi
    waybar
    swayidle
    swaylock
    wl-clipboard # Copy/Paste functionality.
    unstable.kooha
    swaynotificationcenter # Notification center and daemon for Wayland.
    google-chrome
    unstable.obsidian
    # Raspberry Pi Imager
    unstable.rpi-imager
    mediawriter
    zen-browser.default

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

  fonts = {
    packages = with pkgs; [
      inter
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      openmoji-color
    ];
  };

  # Remap the physical left Alt and left Super keys before desktop sessions see
  # them. This makes the keyboard behave as if those two keys were swapped.
  services.interception-tools = {
    enable = true;
    plugins = [ pkgs.interception-tools-plugins.dual-function-keys ];

    # Listen only for the two keys involved in the swap and emit remapped events
    # through uinput.
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c /etc/dual-function-keys.yaml | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_LEFTALT, KEY_LEFTMETA]
    '';
  };

  # Swap physical left Alt and left Super.
  environment.etc."dual-function-keys.yaml".text = ''
    ---
    MAPPINGS:
      - KEY: KEY_LEFTALT
        TAP: KEY_LEFTMETA
        HOLD: KEY_LEFTMETA
        HOLD_START: BEFORE_CONSUME

      - KEY: KEY_LEFTMETA
        TAP: KEY_LEFTALT
        HOLD: KEY_LEFTALT
        HOLD_START: BEFORE_CONSUME
  '';

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
