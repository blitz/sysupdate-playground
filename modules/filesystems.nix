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
        partConf = config.image.repart.partitions."10-esp".repartConfig;
      in
      {
        device = "/dev/disk/by-partuuid/${partConf.UUID}";
        fsType = partConf.Format;
      };

    "/usr" = {
      device = "/dev/mapper/usr";
      # explicitly mount it read-only otherwise systemd-remount-fs will fail
      options = [ "ro" ];
      fsType = config.image.repart.partitions."20-store".repartConfig.Format;
    };

    "/nix/store" =
      {
        device = "/usr/nix/store";
        options = [ "bind" ];
      };
  };
}
