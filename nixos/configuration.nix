# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
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

  # HP EliteBook 645 G9: BIOS ships ACPI tables tuned for Windows. Declaring
  # Windows 2020 compatibility makes the firmware expose correct power-delivery
  # and AC-adapter state that Linux would otherwise miss (charger not detected
  # after resume, UCSI not binding).
  boot.kernelParams = [
    ''acpi_osi="Windows 2020"''
    "resume=/dev/mapper/luks-aed0c447-af30-4cc5-b955-cb4e269909dc"
    "resume_offset=35557376"
  ];

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

  # X server hosts the i3 session.
  services.xserver.enable = true;

  # Use GDM for session selection and prefer i3 as the default session.
  services.displayManager.gdm.enable = true;
  # Keep a GUI desktop available in GDM as a fallback desktop session.
  services.desktopManager.gnome.enable = true;

  # Enable i3. i3lock-color provides the `i3lock` binary used by xss-lock.
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      i3status
      i3lock-color
    ];
  };

  # Portal setup. On X11 only the GTK backend is needed; screen sharing works
  # through plain X capture rather than a compositor portal.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # The i3 module registers the "none+i3" session with the greeter itself.
  services.displayManager.defaultSession = "none+i3";

  # Enables Gnome Keyring to store secrets for applications.
  services.gnome.gnome-keyring.enable = true;

  # Required for rpi-imager: allows read/write access to storage devices
  services.udisks2.enable = true;

  # Required for privilege escalation prompts in graphical applications.
  security.polkit.enable = true;

  # Preserve X environment variables when escalating with sudo.
  security.sudo.extraConfig = ''
    Defaults env_keep = "DISPLAY XAUTHORITY"
  '';

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;
  # Configure keymap in X11. X owns keyboard config now that i3 (unlike sway)
  # has no input configuration of its own.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:nocaps";
  };

  # Touchpad and pointer behaviour, previously set in the sway config.
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      tappingButtonMap = "lrm";
      disableWhileTyping = true;
    };
    mouse.naturalScrolling = true;
  };

  # Configure console keymap
  console.keyMap = "us";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplipWithPlugin ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # KVM/QEMU virtualization for VMs (e.g. Windows guest via virt-manager).
  # OVMF gives UEFI + Secure Boot; swtpm emulates TPM 2.0, required by Win11.
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    # logind counts the session as docked while a second display is connected,
    # and the external monitor is the only enabled output anyway, so closing the
    # lid there should keep the machine running rather than put it to sleep.
    HandleLidSwitchDocked = "ignore";
    IdleAction = "suspend-then-hibernate";
    # Keep suspend after the xidlehook display timeout so the screen blanks at
    # 8 minutes before the system sleeps.
    IdleActionSec = "15min";
  };

  # After suspending, hibernate to disk if still asleep this long (safety net
  # for battery drain / long lid-closed periods). Requires swapDevices below.
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "45min";
    # systemd only evaluates HibernateDelaySec when it wakes from the s2idle
    # phase, and the RTC alarm for that wakeup comes from its battery-discharge
    # estimate, not from HibernateDelaySec. Left at the 60min default the
    # estimate drifted to multi-hour alarms, so hibernation actually fired
    # after 4-14h instead of 45min. Capping the estimation interval bounds the
    # wakeup so the delay above is honoured.
    SuspendEstimationSec = "45min";
    # Hibernate on the same schedule when docked; the delay is about not
    # losing the session, and AC can be unplugged while the lid is closed.
    HibernateOnACPower = "yes";
  };

  # Swapfile for hibernation (suspend-then-hibernate above). Size >= RAM.
  # NOTE: resume_offset in boot.kernelParams must be filled in AFTER first
  # rebuild creates this file — see comment near kernelParams below.
  swapDevices = [
    { device = "/swapfile"; size = 20 * 1024; }
  ];
  boot.resumeDevice = "/dev/mapper/luks-aed0c447-af30-4cc5-b955-cb4e269909dc";

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

  # PowerTOP autotune disabled: it sets USB autosuspend on all devices, which
  # causes input freezes on external HID peripherals (keyboard/mouse dongle).
  # auto-cpufreq handles CPU scaling; thermald handles thermal management.
  powerManagement.powertop.enable = false;

  # Re-scan power supply state after resume in case ACPI didn't fire the event.
  # Reload ath11k_pci: driver doesn't reinitialize cleanly after wakeup.
  powerManagement.resumeCommands = ''
    sleep 2
    ${pkgs.udev}/bin/udevadm trigger --subsystem-match=power_supply
    ${pkgs.kmod}/bin/modprobe -r ath11k_pci
    ${pkgs.kmod}/bin/modprobe ath11k_pci
  '';

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
      "libvirtd"
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
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyFinal: pyPrev: {
          # test expectations use "pkg@ url" but pipx now emits "pkg @ url"
          pipx = pyPrev.pipx.overrideAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [
              "test_parse_specifier_for_metadata"
              "test_fix_package_name"
            ];
          });
        })
      ];
    })
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
    vscode
    emacs

    # core runtime/deps
    libsecret
    gnome-keyring
    seahorse
    nodejs
    powershell

    # cloud / provisioning
    awscli2
    (azure-cli.withExtensions (with azure-cli.extensions; [ virtual-network-manager ]))
    oci-cli
    terraform

    # cli tools
    git
    git-credential-manager
    gh
    wget
    ripgrep
    fd
    jq # Also drives the polybar split-direction module.
    bind # nslookup
    nmap
    usbutils
    ispell
    shellcheck
    nixfmt
    lazygit
    parted
    psmisc
    unzip
    # monitoring
    htop
    btop

    # virtualization
    virtio-win # Windows guest drivers ISO (disk/net perf)

    # terminal
    fish
    kitty
    ghostty
    tmux

    # language
    python3
    python3Packages.pip
    pipx

    # desktop
    solaar
    flameshot
    brightnessctl
    networkmanagerapplet
    pavucontrol
    rofi # Application launcher.
    # Status bar. The default build has neither the i3 nor the PulseAudio
    # module compiled in, and the bar needs both.
    (polybar.override {
      i3Support = true;
      pulseSupport = true;
    })
    feh # Sets the desktop wallpaper; X11 has no compositor to do it.
    xss-lock # Bridges logind lock/sleep signals to i3lock.
    xidlehook # Staged idle timeouts (dim, lock, display off).
    xset # DPMS control, used by the idle timeout above.
    xclip # Copy/Paste functionality.
    dunst # Notification daemon.
    libnotify # notify-send, for scripts that raise notifications.
    google-chrome
    obsidian
    rpi-imager
    mediawriter
    prusa-slicer
    zen-browser.default

    # emacs dependencies
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

    # doom emacs tooling
    sqlite # :tools lookup, backs dash-docs
    pandoc # :lang markdown, backs markdown-preview
    shfmt # :lang sh formatting

    # language servers
    pyright
    yaml-language-server
    terraform-ls
    typescript
    typescript-language-server

    # python tooling (doom :lang python expects these on PATH)
    black
    isort
    pipenv
    python3Packages.pytest
    python3Packages.pyflakes

    # ansible
    ansible

    # cluster
    kubectl
    kubeseal
    kubernetes-helm
    argocd

    # qol
    kubectx # includes kubens
    k9s
  ];

  fonts = {
    packages = with pkgs; [
      inter
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      symbola # Emacs' unicode fallback font
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

  # Explicitly keep USB HID devices (keyboard, mouse dongle) out of autosuspend.
  # Belt-and-suspenders: powertop is disabled, but guard against any future
  # power manager re-enabling it.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usbhid", TEST=="power/control", ATTR{power/control}="on"
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
