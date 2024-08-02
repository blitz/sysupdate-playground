{ config, pkgs, lib, modulesPath, ... }: {

  imports = [
    "${modulesPath}/image/repart.nix"
  ];

  systemd.sysupdate = {
    enable = true;

    transfers = {
      "10-uki" = {
        Source = {
          MatchPattern = [
            "${config.boot.uki.name}_@v+@l-@d.efi"
            "${config.boot.uki.name}_@v+@l.efi"
            "${config.boot.uki.name}_@v.efi"
          ];
          # Path = "https://download.example.com/";
          # Type = "url-file";
          Path = "/var/updates/";
          Type = "regular-file";
        };
        Target = {
          InstancesMax = 2;
          MatchPattern = ''
            ${config.boot.uki.name}_@v+@l-@d.efi \
            ${config.boot.uki.name}_@v+@l.efi \
            ${config.boot.uki.name}_@v.efi
          '';
          Mode = "0444";
          Path = "/EFI/Linux";
          PathRelativeTo = "boot";

          TriesDone = 0;
          TriesLeft = 3;

          Type = "regular-file";
        };
        Transfer = {
          ProtectVersion = "%A";
        };
      };

      "20-store" = {
        Source = {
          MatchPattern = [
            "store_@v.img"
          ];
          # Path = "https://download.example.com/";
          # Type = "url-file";
          Path = "/var/updates/";
          Type = "regular-file";
        };

        Target = {
          InstancesMax = 2;
          Path = "auto";
          MatchPattern = "store_@v";

          Type = "partition";
        };
      };
    };
  };

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

  fileSystems = {
    "/" =
      let
        partConf = config.image.repart.partitions."root".repartConfig;
      in
      {
        device = "/dev/disk/by-partuuid/${partConf.UUID}";
        fsType = partConf.Format;
      };

    "/boot" =
      let
        partConf = config.image.repart.partitions."esp".repartConfig;
      in
      {
        device = "/dev/disk/by-partuuid/${partConf.UUID}";
        fsType = partConf.Format;
      };

    "/nix/store" =
      let
        partConf = config.image.repart.partitions."store".repartConfig;
      in
      {
        device = "/dev/disk/by-partlabel/${partConf.Label}";
        fsType = partConf.Format;
      };
  };

  image.repart =
    let
      efiArch = pkgs.stdenv.hostPlatform.efiArch;
    in
    {
      name = config.boot.uki.name;
      split = true;

      partitions = {
        "esp" = {
          contents = {
            "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
              "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";

            "/EFI/Linux/${config.system.boot.loader.ukiFile}".source =
              "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
          };
          repartConfig = {
            Type = "esp";
            UUID = "c12a7328-f81f-11d2-ba4b-00a0c93ec93b"; # Well known
            Format = "vfat";
            SizeMinBytes = "256M";
            SplitName = "-";
          };
        };
        "store" = {
          storePaths = [ config.system.build.toplevel ];
          stripNixStorePrefix = true;
          repartConfig = {
            Type = "linux-generic";
            Label = "store_${config.system.image.version}";
            Format = "squashfs";
            Minimize = "off";
            SizeMinBytes = "1G";
            SizeMaxBytes = "1G";
            SplitName = "store";
          };
        };

        # Placeholder for the second installed Nix store.
        "store-empty" = {
          repartConfig = {
            Type = "linux-generic";
            Label = "_empty";
            Minimize = "off";
            SizeMinBytes = "1G";
            SizeMaxBytes = "1G";
            SplitName = "-";
          };
        };

        "root" = {
          repartConfig = {
            Type = "root";
            UUID = "4f68bce3-e8cd-4db1-96e7-fbcaf984b709"; # Well known
            Format = "xfs";
            Label = "nixos";
            Minimize = "off";
            SizeMinBytes = "2G";
            SizeMaxBytes = "2G";
            SplitName = "-";
          };
        };
      };
    };


}
