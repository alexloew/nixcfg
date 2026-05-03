# SSH Configuration
# SSH client settings

{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
  };
}
