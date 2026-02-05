# Helix Editor Configuration
# Modal editor settings and LSP integration

{ pkgs, ... }:

{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "catppuccin_mocha";
      editor = {
        line-number = "relative";
        mouse = false;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        file-picker.hidden = false;
      };
    };
    # Language servers
    extraPackages = with pkgs; [
      marksman            # Markdown
      nil                 # Nix
      rust-analyzer       # Rust
      pyright             # Python
      yaml-language-server
    ];
  };
}
