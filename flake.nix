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

      nixosConfigurations.demo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ config, lib, pkgs, modulesPath, ... }: {
            imports = [
              ./modules/minimize.nix
              ./modules/filesystems.nix
            ];

            boot.uki.name = "appliance";
            system.image.version = builtins.toString osVersion;

            boot.kernelParams = [ "console=ttyS0" ];

            system.stateVersion = "24.11";
            boot.loader.grub.enable = false;

            # Not compatible with system.etc.overlay.enable yet.
            # users.mutableUsers = false;

            services.getty.autologinUser = "root";
            #users.users.root.initialPassword = "root";

            boot.initrd.systemd.enable = true;

            networking = {
              useNetworkd = true;
              firewall.enable = false;
            };

            # Faster boot.
            systemd.network.wait-online.enable = false;

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
          })
        ];
      };
    };
}
