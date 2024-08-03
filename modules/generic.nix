{ pkgs, lib, ... }: {

  boot.uki.name = "appliance";
  boot.kernelParams = [ "console=ttyS0" ];

  # TODO Is there a way to override these?
  #system.nixos.release = "2024-08";
  #system.nixos.codeName = "Babylon";

  system.nixos.distroId = "applianceos";
  system.nixos.distroName = "ApplianceOS";

  # Not compatible with system.etc.overlay.enable yet.
  # users.mutableUsers = false;

  services.getty.autologinUser = "root";

  boot.initrd.systemd.enable = true;

  # Don't accumulate crap.
  boot.tmp.cleanOnBoot = true;
  services.journald.extraConfig = ''
    SystemMaxUse=10M
  '';

  # Debugging
  environment.systemPackages = with pkgs; [
    tmux
    parted
    dstat
  ];

  # Prepare a fake update.
  systemd.services.update-prepare-debug = {
    description = "Prepare a fake update";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ]; # Ensures the script runs after file systems are mounted.
    requires = [ "local-fs.target" ]; # Ensure file systems are mounted.

    script = ''
      mkdir /var/updates
      cp /boot/EFI/Linux/appliance_17.efi /var/updates/appliance_18.efi
      cp /dev/disk/by-partlabel/store_17 /var/updates/store_18.img
    '';

    serviceConfig = {
      Type = "oneshot"; # Ensures the service runs once and then exits.
    };
  };

  system.stateVersion = "24.11";
}
