# herdr - terminal workspace manager / multiplexer for AI coding agents.
# Pulled from its upstream flake (no nixpkgs package yet).
# https://github.com/ogulcancelik/herdr
#
# Local patch: agent-detection for wrapped launchers. Our `claude` runs inside
# the newt/dropship bubblewrap sandbox (`bwrap … -- claude`) and execs a
# version-named binary (`…/claude/versions/2.1.204`), neither of which herdr's
# process-name matching recognizes, so panes report `unknown` and get pruned.
# Tracks https://github.com/ogulcancelik/herdr/issues/803 — drop the override
# once a fix lands upstream and this input is bumped past it.

{ pkgs, inputs, ... }:

let
  herdr = inputs.herdr.packages.${pkgs.system}.default.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./herdr-agent-detection-wrappers.patch ];
  });
in
{
  home.packages = [ herdr ];
}
