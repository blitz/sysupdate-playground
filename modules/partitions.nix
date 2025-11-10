{ config, pkgs, lib, modulesPath, ... }: {

  imports = [
    "${modulesPath}/image/repart.nix"
  ];

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

            # systemd-boot configuration
            "/loader/loader.conf".source = (pkgs.writeText "$out" ''
              timeout 3
            '');

            # EFI shell for modifying EFI variables and running startup scripts
            # Placed in a separate directory so it is not added to boot entries by default.
            "/tools/shell.efi".source = pkgs.edk2-uefi-shell.efi;

            # Factory Reset EFI shell script.
            # This sets or unsets the factory reset EFI variable for the next boot.
            # This variable is observed and reset by the systemd-repart.service
            "/tools/factoryreset.nsh".source = (pkgs.writeText "$out" ''
              setvar FactoryReset -guid 8cf2644b-4b0b-428f-9387-6d876050dc67 -nv -rt =%1

              pause
              reset
            '');

            # Factory Reset boot loader entry
            "/loader/entries/factoryreset_enable.conf".source = (pkgs.writeText "$out" ''
              title Enable Factory Reset

              options -nostartup -nomap
              options \tools\factoryreset.nsh L"t"
              efi tools/shell.efi
            '');
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
          nixStorePrefix = "/";
          repartConfig = {
            Type = "linux-generic";
            Label = "store_${config.system.image.version}";
            Format = "squashfs";
            Minimize = "off";
            ReadOnly = "yes";

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

        # Persistent storage
        "var" = {
          repartConfig = {
            Type = "var";
            UUID = "4d21b016-b534-45c2-a9fb-5c16e091fd2d"; # Well known
            Format = "xfs";
            Label = "nixos-persistent";
            Minimize = "off";

            # Has to be large enough to hold update files.
            SizeMinBytes = "2G";
            SizeMaxBytes = "2G";
            SplitName = "-";

            # Wiping this gives us a clean state.
            FactoryReset = "yes";
          };
        };
      };
    };

    boot.initrd.systemd.repart = {
      enable = true;
      device = "/dev/sda";
    };

    systemd.repart = {
      # Only run during boot before switching root, not again as system service.
      # This should only take action for factory reset.
      enable = false;
      partitions = {
        "var" = config.image.repart.partitions."var".repartConfig;
      };
    };

    # Ensure all filesystem checks happen after the initrd reconfigured the drive.
    boot.initrd.systemd.services."systemd-fsck@" = {
      after = [ "systemd-repart.service" ];
    };
}
