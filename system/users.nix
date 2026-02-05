# User Configuration
# User accounts and groups

{ config, pkgs, ... }:

{
  users.users.alexloewenthal = {
    isNormalUser = true;
    description = "Alex Loewenthal";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # User-specific system packages (prefer home-manager for most)
    ];
  };
}
