# Applications - Aggregator
# CLI utilities and GUI applications

{ config, pkgs, ... }:

{
  imports = [
    ./cli.nix
    ./gui.nix
  ];
}
