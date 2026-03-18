# Editors Configuration - Aggregator
# Text editors and their language servers

{ config, pkgs, inputs, ... }:

{
  imports = [
    # cursor.nix removed: nflx-nixcfg.nixosModules.ai provides cursor
    ./helix.nix
  ];
}
