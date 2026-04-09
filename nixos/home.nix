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

  home.file.".config/cosmic".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/cosmic/.config/cosmic";

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

  # Install rpi-imager-root wrapper command for easy terminal access
  # Provides passwordless sudo access to rpi-imager with proper Wayland support
  home.packages = [ rpiImagerRoot ];
}