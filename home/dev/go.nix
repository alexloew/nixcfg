# Go Development
{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    go
    gopls                    # language server
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
