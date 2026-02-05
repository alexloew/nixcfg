# Shell Configuration - Aggregator
# Terminal environment: shell, prompt, version control, remote access

{ config, pkgs, ... }:

{
  imports = [
    ./bash.nix
    ./git.nix
    ./ssh.nix
    ./starship.nix
  ];
}
