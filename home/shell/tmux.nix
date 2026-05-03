# Tmux Configuration
# Terminal multiplexer with vim-style keybinds
# Yazi and lazygit as popup overlays per https://rushter.com/blog/helix-editor/

{ pkgs, ... }:

let
  workspaceLayout = pkgs.writeShellScript "tmux-workspace" ''
    dir="$1"
    name="$(basename "$dir")"

    tmux new-window -c "$dir" -n "$name"
    tmux split-window -h -c "$dir" -l 30%
    tmux send-keys 'claude' Enter
    tmux select-pane -L
    tmux split-window -v -c "$dir" -l 25%
    tmux select-pane -U
    tmux send-keys 'yazi' Enter
    tmux select-pane -D
    shell=$(tmux display-message -p "#{pane_id}")
    (sleep 0.5 && tmux send-keys -t "$shell" C-u) &
  '';
in

{
  programs.tmux = {
    enable = true;
    prefix = "C-\\\\";
    baseIndex = 1;
    escapeTime = 50;
    historyLimit = 1000000;
    keyMode = "vi";
    mouse = true;
    terminal = "xterm-256color";

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];

    extraConfig = ''
      # Secondary prefix
      set-option -g prefix2 C-b

      # Appearance
      setw -g mode-style 'fg=black bg=blue bold'
      setw -g clock-mode-colour yellow
      set -g pane-border-style 'fg=red'
      set -g pane-active-border-style 'fg=yellow'

      # Status bar
      set -g status-position bottom
      set -g status-justify centre
      set -g status-style 'fg=red'
      set -g status-left '#[fg=green]#S-#(whoami) #H'
      set -g status-left-length 30
      set -g status-right ""
      set -g status-right-length 0
      setw -g window-status-current-style 'fg=black bg=blue'
      setw -g window-status-current-format ' #I #W #F '
      setw -g window-status-style 'fg=red bg=black'
      setw -g window-status-format ' #I #[fg=white]#W #[fg=yellow]#F '
      setw -g window-status-bell-style 'fg=yellow bg=red bold'
      set -g message-style 'fg=yellow bg=red bold'

      # Pane resizing (vim-style)
      bind-key J resize-pane -D 5
      bind-key K resize-pane -U 5
      bind-key H resize-pane -L 5
      bind-key L resize-pane -R 5
      bind-key M-j resize-pane -D
      bind-key M-k resize-pane -U
      bind-key M-h resize-pane -L
      bind-key M-l resize-pane -R

      # Pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Splits (open in current path)
      bind-key v split-window -v -c "#{pane_current_path}"
      bind-key s split-window -h -c "#{pane_current_path}"
      bind c command-prompt -p "Directory:" -I "#{pane_current_path}" "run-shell '${workspaceLayout} %1'"

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # Vi copy mode
      bind-key / copy-mode \; send-key ?
      unbind -T copy-mode-vi Enter
      unbind -T copy-mode-vi Space
      bind-key -T edit-mode-vi Up send-keys -X history-up
      bind-key -T edit-mode-vi Down send-keys -X history-down
      bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

      # Terminal overrides (cursor shape + true color passthrough)
      set -ga terminal-overrides ',*:Ss=\E[%p1%d q:Se=\E[2 q'
      set -as terminal-overrides ',xterm*:RGB'

      # Yazi file manager popup (prefix + y)
      bind-key y display-popup -d '#{pane_current_path}' -x R -h 95% -w 95% -E 'tmux new-session yazi \; set status off'

      # Lazygit popup (prefix + g)
      bind-key g popup -E -w 95% -h 95% -d '#{pane_current_path}' lazygit

      # Open terminal output in helix (prefix + e)
      bind-key e display-popup -w 95% -h 90% -E "tmux capture-pane -Jp -S- | hx -"

      # Generic popup shell (prefix + z)
      bind-key z popup -E -w 95% -h 90%

      # Passthrough for yazi image preview
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      # UTF-8
      set -q -g status-utf8 on
      setw -q -g utf8 on

      # Focus events (for editor auto-save)
      set -g focus-events on
    '';
  };
}
