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
