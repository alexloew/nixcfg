# herdr - terminal workspace manager / multiplexer for AI coding agents.
# Pulled from its upstream flake (no nixpkgs package yet).
# https://github.com/ogulcancelik/herdr

{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.herdr.packages.${pkgs.system}.default
  ];
}
