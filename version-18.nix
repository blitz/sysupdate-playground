{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;

    ohMyZsh = {
      enable = true;
    };

    promptInit = ''
      PS1="${config.system.image.version} $PS1"
    '';
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  users.defaultUserShell = pkgs.zsh;
}
