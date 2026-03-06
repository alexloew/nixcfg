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
    extraGroups = [ "networkmanager" "wheel" "tss" ];
    packages = with pkgs; [
      # User-specific system packages (prefer home-manager for most)
    ];
  };

  # Preserve SSH_AUTH_SOCK through sudo so flake fetches from
  # private repos (e.g. nflx-nixcfg) work with nixos-rebuild switch
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';
}
