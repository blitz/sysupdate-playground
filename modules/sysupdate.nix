{ config, pkgs, ... }: {
  systemd.sysupdate = {
    enable = true;

    transfers = {
      "10-uki" = {
        Source = {
          MatchPattern = [
            "${config.boot.uki.name}_@v.efi.xz"
          ];

          # We could fetch updates from the network as well:
          #
          # Path = "https://download.example.com/";
          # Type = "url-file";
          Path = "/var/updates/";
          Type = "regular-file";
        };
        Target = {
          InstancesMax = 2;
          MatchPattern = [
            "${config.boot.uki.name}_@v.efi"
          ];

          Mode = "0444";
          Path = "/EFI/Linux";
          PathRelativeTo = "boot";

          Type = "regular-file";
        };
        Transfer = {
          ProtectVersion = "%A";
        };
      };

      "20-store" = {
        Source = {
          MatchPattern = [
            "store_@v.img.xz"
          ];
          # Path = "https://download.example.com/";
          # Type = "url-file";
          Path = "/var/updates/";
          Type = "regular-file";
        };

        Target = {
          InstancesMax = 2;

          # "auto" doesn't work, because / is a tmpfs and the
          # heuristic is not that smart. So we hardcode the device
          # here for the different platforms.
          #
          # Path = "auto";
          Path = {
            x86_64-linux = "/dev/sda";
            aarch64-linux = "/dev/vda";
            riscv64-linux = "/dev/vda";
          }."${pkgs.stdenv.system}";

          MatchPattern = "store_@v";

          Type = "partition";
          ReadOnly = "yes";
        };
      };
    };
  };
}
