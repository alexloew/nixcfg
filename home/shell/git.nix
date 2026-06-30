# Git Configuration
# Version control settings

{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Alex Loewenthal";
    userEmail = "alexloewenthal@netflix.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      # Use gh as the credential helper, resolved from PATH rather than a
      # pinned /nix/store path. `gh auth setup-git` bakes an absolute store
      # path into ~/.gitconfig, which breaks on every rebuild/GC once that
      # store path is collected. Referencing `gh` on PATH survives rebuilds.
      "credential \"https://github.com\"".helper = "!gh auth git-credential";
      "credential \"https://gist.github.com\"".helper = "!gh auth git-credential";
      "credential \"https://github.netflix.net\"".helper = "!gh auth git-credential";
    };
    aliases = {
      gp  = "pull";
      gP  = "push";
      gs  = "status -s";
      ga  = "add";
      gc  = "commit";
      gcm = "commit -m";
      gco = "checkout";
      gb  = "branch";
      gl  = "log --oneline --graph --decorate -15";
      gd  = "diff";
      gds = "diff --staged";
      gf  = "fetch";
      grb = "rebase";
      gst = "stash";
    };
  };
}
