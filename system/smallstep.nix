# Smallstep - certificate/identity tooling (work)
# Packages sourced from github:smallstep/nur

{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    inputs.smallstep-nur.packages.${pkgs.system}.step-agent
  ];
}
