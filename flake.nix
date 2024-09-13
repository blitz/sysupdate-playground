{
  description = "systemd-sysupdate / systemd-repart Example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      inherit (nixpkgs) lib;

      buildSystem = "x86_64-linux";
      buildPkgs = nixpkgs.legacyPackages."${buildSystem}";
    in
    (flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ] (system:
      let
        isBuildSystem = system == buildSystem;
        pkgs = nixpkgs.legacyPackages."${system}";
        crossPkgs =
          if isBuildSystem
          then nixpkgs.legacyPackages."${system}"
          else import "${nixpkgs}" { localSystem = buildSystem; crossSystem = system; };

        # A convenience wrapper around lib.nixosSystem that configures
        # cross-compilation.
        crossNixos = module: lib.nixosSystem {
          modules = [
            module

            {
              # We could also use these to trigger cross-compilation,
              # but we already have the ready-to-go crossPkgs.
              #
              # nixpkgs.buildPlatform = buildSystem;
              # nixpkgs.hostPlatform = system;
              nixpkgs.pkgs = crossPkgs;
            }
          ];
        };
      in
      # Some outputs only make sense for the build system, e.g. the development shell.
      (lib.optionalAttrs isBuildSystem (import ./buildHost.nix { inherit pkgs; }))
      //
      {
        packages =
          let
            appliance_17 = crossNixos ({ config, lib, pkgs, modulesPath, ... }: {
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
                  cp ${self.packages."${system}".appliance_18_update}/* /var/updates
                '';

                serviceConfig = {
                  Type = "oneshot"; # Ensures the service runs once and then exits.
                };
              };

              system.image.version = "17";
            });

            appliance_18 = crossNixos ({ config, lib, pkgs, modulesPath, ... }: {
              imports = [
                ./base.nix
                ./version-18.nix
              ];

              system.image.version = "18";
            });
          in
          {
            default = self.packages."${system}".appliance_17_image;

            appliance_17_image = self.lib.mkInstallImage appliance_17;
            appliance_17_update = self.lib.mkUpdate appliance_17;

            appliance_18_image = self.lib.mkInstallImage appliance_18;
            appliance_18_update = self.lib.mkUpdate appliance_18;
          };
      })) // {
      lib = {
        # Prepare an update package for the system.
        mkUpdate = nixos:
          let
            config = nixos.config;
          in
          buildPkgs.runCommand "update-${config.system.image.version}"
            {
              nativeBuildInputs = with buildPkgs; [ xz ];
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
          in
          buildPkgs.runCommand "image-${config.system.image.version}"
            {
              nativeBuildInputs = with buildPkgs; [ qemu ];
            } ''
            mkdir -p $out
            qemu-img convert -f raw -O qcow2 \
              -C ${config.system.build.image}/${config.boot.uki.name}_${config.system.image.version}.raw \
              $out/disk.qcow2
          '';
      };
    };
}
