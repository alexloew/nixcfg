# herdr - terminal workspace manager / multiplexer for AI coding agents.
# Pulled from its upstream flake (no nixpkgs package yet).
# https://github.com/ogulcancelik/herdr
#
# Local patch: agent-detection for wrapped launchers. Our `claude` runs inside
# a bubblewrap sandbox (`bwrap … -- claude`) and execs a version-named binary
# (`…/claude/versions/2.1.204`), neither of which herdr's process-name matching
# recognizes, so panes report `unknown` and get pruned. Drop the override once
# a fix lands upstream and this input is bumped past it.

{ config, lib, pkgs, inputs, ... }:

let
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./herdr-agent-detection-wrappers.patch ];
  });
  integrationTargets = [ "claude" "codex" "opencode" "hermes" "pi" ];
in
{
  home.packages = [ herdr ];

  # Nix owns settings; Herdr's settings UI cannot save to this read-only file.
  # Manage only config.toml so sessions, sockets and logs stay writable.
  xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
    onboarding = false;

    theme = {
      name = "kanagawa";
      auto_switch = false;
    };

    ui = {
      agent_panel_sort = "priority";
      show_agent_labels_on_pane_borders = true;
      status_indicators = "symbols";
      toast.delivery = "terminal";
      sound.enabled = false;
    };
  };

  # Keep agent integrations aligned with the pinned Herdr package. Upstream
  # installers merge their registrations into writable agent settings.
  # Run after shared config updates so they cannot overwrite registrations.
  home.activation.herdrIntegrations = lib.hm.dag.entryAfter [
    "linkGeneration"
    "installPiNflxExtensions"
    "updateClaudeConfig"
    "updateClaudeMcpServers"
    "updateCodexConfig"
    "updateHermesConfig"
    "updateOpenCodeConfig"
  ] ''
    (
      # Explicit paths avoid inheriting another agent profile from the caller.
      export HOME=${lib.escapeShellArg config.home.homeDirectory}
      export CLAUDE_CONFIG_DIR="$HOME/.claude"
      export CODEX_HOME="$HOME/.codex"
      export HERMES_HOME="$HOME/.hermes"
      export PI_CODING_AGENT_DIR="$HOME/.pi-nflx/agent"

      run ${pkgs.coreutils}/bin/mkdir -p \
        "$CLAUDE_CONFIG_DIR" "$CODEX_HOME" "$HOME/.config/opencode" \
        "$HERMES_HOME" "$PI_CODING_AGENT_DIR"

      for target in ${lib.escapeShellArgs integrationTargets}; do
        run ${herdr}/bin/herdr integration install "$target"
      done
    )
  '';
}
