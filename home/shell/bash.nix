# Bash Configuration
# Shell settings, aliases, and environment

{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      # Nix Shortcuts
      update = "sudo nixos-rebuild switch";
      flake-up = "nix flake update";
      conf = "cd /etc/nixos && sudo nano flake.nix";
      cleanup = "sudo nix-collect-garbage -d";

      # Navigation
      ll = "ls -alv";
      ".." = "cd ..";
      "..." = "cd ../..";
    };

    # Home Manager automatically handles starship init
    # if programs.starship.enable = true.
  };
}
