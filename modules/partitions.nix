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
}
