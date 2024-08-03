{ config, ... }: {
  networking = {
    useNetworkd = true;

    # Easy debugging.
    firewall.enable = false;
  };

  # Faster boot.
  systemd.network.wait-online.enable = false;
}
