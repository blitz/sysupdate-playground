{ config, ... }: {

  zramSwap = {
    # TODO zram-generator fails to compile for ARM.
    enable = false;

    algorithm = "zstd";
    memoryPercent = 20;
  };

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = [
        "size=20%"
      ];
    };

    "/var" =
      let
        partConf = config.image.repart.partitions."var".repartConfig;
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
}
