{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    lib = {
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
      appliance_17_update = self.lib.mkUpdate self.nixosConfigurations.appliance_17;
      appliance_17_image = self.lib.mkInstallImage self.nixosConfigurations.appliance_17;

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

          # Prepare an update.
          systemd.services.update-prepare-debug = {
            description = "Prepare a fake update";
            wantedBy = [ "multi-user.target" ];
            after = [ "local-fs.target" ]; # Ensures the script runs after file systems are mounted.
            requires = [ "local-fs.target" ]; # Ensure file systems are mounted.

            script = ''
              mkdir /var/updates
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
