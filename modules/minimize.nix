{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];

  # switch-to-configuration-ng reimplements switch-to-configuration, but
  # without perl.
  system.switch = {
    enable = false;
    enableNg = true;
  };

  nix.enable = false;

  system.etc.overlay.enable = true;
  systemd.sysusers.enable = true;

  system.disableInstallerTools = true;
  programs.less.lessopen = null;
  programs.command-not-found.enable = false;
  boot.enableContainers = false;
  environment.defaultPackages = [ ];
}
