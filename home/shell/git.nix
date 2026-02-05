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
  };
}
