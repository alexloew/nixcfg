# User Configuration
# User accounts and groups

{ config, pkgs, ... }:

{
  # Enable zsh at the system level (required for login shell)
  programs.zsh.enable = true;

  users.users.alexloewenthal = {
    isNormalUser = true;
    description = "Alex Loewenthal";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # User-specific system packages (prefer home-manager for most)
    ];
  };
}
