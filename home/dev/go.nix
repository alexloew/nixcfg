# Go Development
{ pkgs, lib, config, ... }:

{
  home.packages = with pkgs; [
    go
    (lib.hiPrio gopls)       # language server (priority over gotools for shared binaries like `modernize`)
    golangci-lint            # linter
    delve                    # debugger
    gotools                  # provides goimports formatter
  ];

  home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/go";
    GOBIN  = "${config.home.homeDirectory}/go/bin";
  };

  home.sessionPath = [ "${config.home.homeDirectory}/go/bin" ];
}
