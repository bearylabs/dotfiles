{ config, pkgs, ... }:

let
  themeToggle = pkgs.writeShellScriptBin "theme-toggle" ''
    set -eu

    mode="''${1:-toggle}"
    config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
    state_file="$config_dir/theme-mode"
    gsettings_bin="${pkgs.glib}/bin/gsettings"

    apply_dark() {
      mkdir -p "$config_dir"
      printf '%s\n' dark > "$state_file"
      "$gsettings_bin" set org.gnome.desktop.interface color-scheme 'prefer-dark'
      "$gsettings_bin" set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    }

    apply_light() {
      mkdir -p "$config_dir"
      printf '%s\n' light > "$state_file"
      "$gsettings_bin" set org.gnome.desktop.interface color-scheme 'default'
      "$gsettings_bin" set org.gnome.desktop.interface gtk-theme 'Adwaita'
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

  powerSource = pkgs.writeShellScriptBin "power-source" ''
    set -eu

    mode="''${1:-status}"

    on_ac() {
      for online in /sys/class/power_supply/*/online; do
        [ -e "$online" ] || continue
        if [ "$(<"$online")" = "1" ]; then
          return 0
        fi
      done
      return 1
    }

    case "$mode" in
      ac)
        on_ac
        ;;
      battery)
        ! on_ac
        ;;
      status)
        if on_ac; then
          printf '%s\n' ac
        else
          printf '%s\n' battery
        fi
        ;;
      *)
        printf '%s\n' "usage: power-source [ac|battery|status]" >&2
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

  home.file.".config/doom".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/doom/.config/doom";

  home.file.".config/fish/config.fish".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/fish/.config/fish/config.fish";

  home.file.".config/ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/ghostty/.config/ghostty";

  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/gitconfig/.gitconfig";

  home.file.".config/i3".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/i3/.config/i3";

  home.file.".config/i3status".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/i3status/.config/i3status";

  home.file.".config/polybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/polybar/.config/polybar";

  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/tmux/.tmux.conf";

  home.file.".config/rofi".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/rofi/.config/rofi";

  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/zsh/.zshrc";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Install helper commands for desktop integration.
  home.packages = [
    powerSource
    themeToggle
  ];
}
