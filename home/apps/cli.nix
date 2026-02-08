# CLI Applications
# Command-line utilities and tools

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # File utilities
    wget
    unzip
    tree
    ripgrep
    fzf

    # File manager
    yazi

    # Git TUI
    lazygit

    # System monitoring
    htop
    btop
    fastfetch

    # Text editing (fallback)
    vim
  ];
}
