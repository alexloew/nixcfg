# Cursor Editor
# AI-powered code editor (VS Code fork)
# https://github.com/alexloew/cursor-nixos-flake

{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.cursor.packages.x86_64-linux.cursor
  ];
}
