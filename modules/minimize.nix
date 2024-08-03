{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  boot.loader.grub.enable = false;

  system.switch.enable = false;
  nix.enable = false;

  system.etc.overlay.enable = true;
  systemd.sysusers.enable = true;

  system.disableInstallerTools = true;
  programs.less.lessopen = null;
  programs.command-not-found.enable = false;
  boot.enableContainers = false;
  environment.defaultPackages = [ ];
}
