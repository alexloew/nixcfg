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
    jq

    # File manager
    yazi

    # Git TUI + GitHub CLI
    lazygit
    gh

    # Screenshots (Wayland)
    grim              # screenshot tool
    slurp             # region selection
    wl-clipboard      # clipboard support (wl-copy)

    # Hardware info
    pciutils          # lspci

    # System monitoring
    htop
    btop
    fastfetch
    osquery

    # Text editing (fallback)
    vim
  ];
}
