{ ... }: {
  imports = [
    ./modules/minimize.nix
    ./modules/generic.nix
    ./modules/filesystems.nix
    ./modules/partitions.nix
    ./modules/network.nix
    ./modules/sysupdate.nix
  ];
}
