# Zsh Configuration
# Minimal zsh setup per https://rushter.com/blog/zsh-shell/
# No Oh My Zsh - fast startup, starship prompt, fzf history search

{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;

    history = {
      size = 1000000000;
      save = 1000000000;
      extended = true;
    };

    # Vi mode
    defaultKeymap = "viins";

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

    # initExtra was renamed to initContent (general config = default mkOrder 1000).
    initContent = ''
      # Fix backspace in vi mode
      bindkey -v '^?' backward-delete-char

      # fzf keybindings (Ctrl+R for history search)
      source <(fzf --zsh)
    '';
  };

  # fzf integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
