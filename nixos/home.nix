{ config, pkgs, ... }:

let
  # Wrapper script for launching rpi-imager with root privileges
  # - Executes rpi-imager directly if already running as root
  # - Otherwise escalates using sudo (no password required via sudoers config)
  # - Sets QT_QPA_PLATFORM=wayland to ensure GUI uses Wayland, not X11
  # - Preserves session environment (WAYLAND_DISPLAY, DISPLAY, etc.) through sudo
  #
  # Usage: rpi-imager-root [options]
  # Requires: user in wheel group + security.sudo.wheelNeedsPassword = false
  rpiImagerRoot = pkgs.writeShellScriptBin "rpi-imager-root" ''
    if [ "$(id -u)" -eq 0 ]; then
      exec /run/current-system/sw/bin/rpi-imager "$@"
    fi
    export QT_QPA_PLATFORM=wayland
    export XDG_SESSION_TYPE=wayland
    exec /run/wrappers/bin/sudo /run/current-system/sw/bin/rpi-imager "$@"
  '';

  themeToggle = pkgs.writeShellScriptBin "theme-toggle" ''
    set -eu

    mode="''${1:-toggle}"
    config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
    state_file="$config_dir/theme-mode"
    gsettings_bin="${pkgs.glib}/bin/gsettings"
    swaymsg_bin="${pkgs.sway}/bin/swaymsg"

    apply_dark() {
      mkdir -p "$config_dir"
      printf '%s\n' dark > "$state_file"
      "$gsettings_bin" set org.gnome.desktop.interface color-scheme 'prefer-dark'
      "$gsettings_bin" set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

      if [ -n "''${SWAYSOCK:-}" ]; then
        "$swaymsg_bin" 'output * bg #24273a solid_color' >/dev/null
      fi
    }

    apply_light() {
      mkdir -p "$config_dir"
      printf '%s\n' light > "$state_file"
      "$gsettings_bin" set org.gnome.desktop.interface color-scheme 'default'
      "$gsettings_bin" set org.gnome.desktop.interface gtk-theme 'Adwaita'

      if [ -n "''${SWAYSOCK:-}" ]; then
        "$swaymsg_bin" 'output * bg #94d2da solid_color' >/dev/null
      fi
    }

    current_mode() {
      if [ -f "$state_file" ]; then
        cat "$state_file"
      else
        current="$("$gsettings_bin" get org.gnome.desktop.interface color-scheme 2>/dev/null || true)"
        if [ "$current" = "'prefer-dark'" ]; then
          printf '%s\n' dark
        else
          printf '%s\n' light
        fi
      fi
    }

    case "$mode" in
      dark)
        apply_dark
        ;;
      light)
        apply_light
        ;;
      toggle)
        if [ "$(current_mode)" = "dark" ]; then
          apply_light
        else
          apply_dark
        fi
        ;;
      apply)
        if [ "$(current_mode)" = "dark" ]; then
          apply_dark
        else
          apply_light
        fi
        ;;
      *)
        printf '%s\n' "usage: theme-toggle [dark|light|toggle|apply]" >&2
        exit 1
        ;;
    esac
  '';
in

{
  home.stateVersion = "24.11";

  fonts.fontconfig = {
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

  home.file.".config/Code/User/keybindings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/code/.config/Code/User/keybindings.json";

  home.file.".config/Code/User/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/code/.config/Code/User/settings.json";

  # home.file.".config/cosmic".source =
  #   config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/cosmic/.config/cosmic";

  home.file.".config/doom".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/doom/.config/doom";

  home.file.".config/fish/config.fish".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/fish/.config/fish/config.fish";

  home.file.".config/ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/ghostty/.config/ghostty";

  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/gitconfig/.gitconfig";

  home.file.".config/hypr".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/hypr/.config/hypr";

  home.file.".config/sway".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/sway/.config/sway";

  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/tmux/.tmux.conf";

  home.file.".config/waybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/waybar/.config/waybar";

  home.file.".config/wofi".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/wofi/.config/wofi";

  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/zsh/.zshrc";

  # Install helper commands for desktop integration.
  home.packages = [
    rpiImagerRoot
    themeToggle
  ];
}
