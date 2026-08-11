# Bash Configuration
# Shell settings, aliases, and environment

{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      # Nix Shortcuts — the Git checkout is the authoritative flake.
      update = "nh os switch";
      nix-test = "nh os test";
      flake-up = "nix flake update --flake /home/alexloewenthal/gh-personal/nixcfg";
      conf = "cd /home/alexloewenthal/gh-personal/nixcfg";
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
