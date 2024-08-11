{
  description = "systemd-sysupdate / systemd-repart Example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    lib = {
      # Prepare an update package for the system.
      mkUpdate = nixos:
        let
          config = nixos.config;
          pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgs;
        in
        nixos.pkgs.runCommand "update-${config.system.image.version}"
          {
            nativeBuildInputs = with pkgs; [ xz ];
          } ''
          mkdir -p $out
          xz -1 -cz ${config.system.build.uki}/${config.system.boot.loader.ukiFile} \
            > $out/${config.system.boot.loader.ukiFile}.xz
          xz -1 -cz ${config.system.build.image}/${config.boot.uki.name}_${config.system.image.version}.store.raw \
            > $out/store_${config.system.image.version}.img.xz
        '';

      # Prepare a ready-to-boot disk image.
      mkInstallImage = nixos:
        let
          config = nixos.config;
          pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgs;
        in
        nixos.pkgs.runCommand "update-${config.system.image.version}"
          {
            nativeBuildInputs = with pkgs; [ qemu ];
          } ''
          mkdir -p $out
          qemu-img convert -f raw -O qcow2 -C ${config.system.build.image}/${config.boot.uki.name}_${config.system.image.version}.raw $out/disk.qcow2
        '';
    };


    packages.x86_64-linux = {
      default = self.packages.x86_64-linux.appliance_17_image;

      appliance_17_image = self.lib.mkInstallImage self.nixosConfigurations.appliance_17;
      appliance_17_update = self.lib.mkUpdate self.nixosConfigurations.appliance_17;

      appliance_18_image = self.lib.mkInstallImage self.nixosConfigurations.appliance_18;
      appliance_18_update = self.lib.mkUpdate self.nixosConfigurations.appliance_18;
    };

    nixosConfigurations.appliance_17 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, lib, pkgs, modulesPath, ... }: {
          imports = [
            ./base.nix
            ./version-17.nix
          ];

          # To avoid having to prepare an update server, we just drop
          # an update into the filesystem.
          systemd.services.update-prepare-debug = {
            description = "Prepare a fake update";
            wantedBy = [ "multi-user.target" ];
            after = [ "local-fs.target" ]; # Ensures the script runs after file systems are mounted.
            requires = [ "local-fs.target" ]; # Ensure file systems are mounted.

            script = ''
              # We configured systemd-sysupdate to look for updates here.
              mkdir /var/updates

              # We can't symlink the update package. systemd-sysupdate doesn't like that.
              cp ${self.packages.x86_64-linux.appliance_18_update}/* /var/updates
            '';

            serviceConfig = {
              Type = "oneshot"; # Ensures the service runs once and then exits.
            };
          };

          system.image.version = "17";
        })
      ];
    };

    nixosConfigurations.appliance_18 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ({ config, lib, pkgs, modulesPath, ... }: {
          imports = [
            ./base.nix
            ./version-18.nix
          ];

          system.image.version = "18";
        })
      ];
    };
  };
}
