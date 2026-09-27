{ pkgs, ... }:

{
  imports = [
    ../keyboard-remaps.nix
  ];

  # The HP EliteBook 645 G9 BIOS ships ACPI tables tuned for Windows.
  # Declaring Windows 2020 compatibility makes the firmware expose correct
  # power-delivery and AC-adapter state after resume and lets UCSI bind.
  boot.kernelParams = [
    ''acpi_osi="Windows 2020"''
    "resume=/dev/mapper/luks-aed0c447-af30-4cc5-b955-cb4e269909dc"
    "resume_offset=35557376"
  ];

  # Swapfile and encrypted root device used to hibernate this installation.
  # The resume offset must be updated if the swapfile is recreated.
  swapDevices = [
    { device = "/swapfile"; size = 20 * 1024; }
  ];
  boot.resumeDevice = "/dev/mapper/luks-aed0c447-af30-4cc5-b955-cb4e269909dc";

  # The firmware's platform hibernation path can abort on a pending wakeup
  # event after the image and GPU state have already been torn down. Direct
  # shutdown avoids the broken firmware hand-off.
  systemd.sleep.settings.Sleep.HibernateMode = "shutdown";

  # Refresh the AC-adapter state and reload the laptop's Wi-Fi driver after
  # resume; both can otherwise remain in a stale or unusable state.
  powerManagement.resumeCommands = ''
    sleep 2
    ${pkgs.udev}/bin/udevadm trigger --subsystem-match=power_supply
    ${pkgs.kmod}/bin/modprobe -r ath11k_pci
    ${pkgs.kmod}/bin/modprobe ath11k_pci
  '';

  services.udev.extraRules = ''
    # The HP firmware exposes a broken ACPI battery alarm that systemd mistakes
    # for a manual wakeup. Disable it so suspend-then-hibernate uses its RTC
    # timer instead.
    ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT0", TEST=="alarm", ATTR{alarm}="0"
  '';
}
