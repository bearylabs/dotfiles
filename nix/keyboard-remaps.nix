{ pkgs, ... }:

{
  # Turn Caps Lock into Ctrl only on the built-in laptop keyboard. This also
  # matches the virtual clone created by interception-tools below.
  services.xserver.inputClassSections = [
    ''
      Identifier "Built-in keyboard Caps Lock remap"
      MatchProduct "AT Translated Set 2 keyboard"
      MatchIsKeyboard "on"
      Option "XkbOptions" "ctrl:nocaps"
    ''
  ];

  # Remap the physical left Alt and left Super keys on the built-in laptop
  # keyboard before desktop sessions see them. External keyboards are excluded.
  services.interception-tools = {
    enable = true;
    plugins = [ pkgs.interception-tools-plugins.dual-function-keys ];

    # Listen only for the two keys involved in the swap and emit remapped events
    # through uinput.
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c /etc/dual-function-keys.yaml | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          NAME: "AT Translated Set 2 keyboard"
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
}
