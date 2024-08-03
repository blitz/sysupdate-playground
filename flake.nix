{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      osVersion = 17;
    in
    {
      packages.x86_64-linux =
        let
          config = self.nixosConfigurations.demo.config;
        in
        {
          uki = config.system.build.uki;
          partitions = config.system.build.image;
        };

      nixosConfigurations.demo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ config, lib, pkgs, modulesPath, ... }: {
            imports = [
              ./modules/minimize.nix
              ./modules/generic.nix
              ./modules/filesystems.nix
              ./modules/partitions.nix
              ./modules/network.nix
              ./modules/sysupdate.nix
            ];

            system.image.version = builtins.toString osVersion;
          })
        ];
      };
    };
}
