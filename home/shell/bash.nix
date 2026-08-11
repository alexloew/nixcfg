# Bash Configuration
# Shell settings, aliases, and environment

{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      # Nix Shortcuts — the Git checkout is the authoritative flake.
      update = "nh os switch /home/alexloewenthal/gh-personal/nixcfg#nixos";
      nix-test = "nh os test /home/alexloewenthal/gh-personal/nixcfg#nixos";
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
