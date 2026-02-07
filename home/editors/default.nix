# Editors Configuration - Aggregator
# Text editors and their language servers

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./cursor.nix
    ./helix.nix
  ];
}
