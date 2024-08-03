{ config, ... }: {

  systemd.sysupdate = {
    enable = true;

    transfers = {
      "10-uki" = {
        Source = {
          #"${config.boot.uki.name}_@v+@l-@d.efi"
          #"${config.boot.uki.name}_@v+@l.efi"

          MatchPattern = [
            "${config.boot.uki.name}_@v.efi"
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
            "${config.boot.uki.name}_@v+@l-@d.efi"
          ];

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

          # This doesn't work, because / is a tmpfs and the heuristic is not that smart.
          #
          # Path = "auto";
          Path = "/dev/sda";

          MatchPattern = "store_@v";

          Type = "partition";
          ReadOnly = "yes";
        };
      };
    };
  };
}
