# Shell Configuration - Aggregator
# Terminal environment: shell, prompt, multiplexer, version control, remote access

{ config, pkgs, ... }:

{
  imports = [
    ./bash.nix
    ./zsh.nix
    ./tmux.nix
    ./git.nix
    ./ssh.nix
    ./starship.nix
  ];
}
