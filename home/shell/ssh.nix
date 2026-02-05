# SSH Configuration
# SSH client settings

{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
          AddKeysToAgent yes
          IdentityFile ~/.ssh/id_ed25519
    '';
  };
}
