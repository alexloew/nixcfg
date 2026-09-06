# Keybinding cheat sheet

## Niri

### Applications and windows

| Key | Action |
|---|---|
| `Super+Return` | Open Ghostty |
| `Super+Space` | Toggle DMS Spotlight launcher |
| `Super+B` | Open Firefox |
| `Super+Q` | Close focused window |
| `Super+F` | Maximize column |
| `Super+Shift+F` | Toggle fullscreen |
| `Super+Shift+V` | Toggle floating |

### Named workspaces

| Key | Workspace |
|---|---|
| `Super+1` | `media` — Spotify and Obsidian |
| `Super+2` | `web` — Chrome |
| `Super+3` | `terminal` — Ghostty |
| `Super+4` | `chat` — Slack |
| `Super+Shift+1..4` | Move the focused column to the named workspace |
| `Super+5..9`, `Super+0` | Focus indexed workspace 5–10 |
| `Super+Shift+5..9`, `Super+Shift+0` | Move the focused column to indexed workspace 5–10 |

### Navigation and layout

| Key | Action |
|---|---|
| `Super+H/J/K/L` | Focus left/down/up/right |
| `Super+Arrow` | Focus using arrow keys |
| `Super+Shift+H/J/K/L` | Move left/down/up/right |
| `Super+Shift+Arrow` | Move using arrow keys |
| `Super+R` | Cycle preset column width |
| `Super+-` / `Super+=` | Decrease/increase column width |
| `Super+Shift+-` / `Super+Shift+=` | Decrease/increase window height |
| `Super+[` / `Super+]` | Consume or expel a window |
| `Super+mouse wheel` | Move between workspaces or columns |

### DMS

| Key | Action |
|---|---|
| `Super+N` | Notifications |
| `Super+,` | Settings |
| `Super+P` | Notepad |
| `Super+V` | Clipboard manager |
| `Super+X` | Power menu |
| `Super+M` | Process list |
| `Super+Alt+N` | Night mode |
| `Super+Alt+L` | Lock screen |

### Screenshots

| Key | Action |
|---|---|
| `Super+S` | Current screen to `~/Pictures/Screenshots/` |
| `Super+Alt+S` | Interactive region to `~/Pictures/Screenshots/` |
| `Super+Shift+S` | Region to clipboard |
| `Super+Shift+Alt+S` | Focused window to `~/Pictures/Screenshots/` |

## tmux

Primary prefix: `Ctrl+\`. Secondary prefix: `Ctrl+B`.

### Windows and panes

| Key | Action |
|---|---|
| `prefix c` | New window in the current path |
| `prefix 1..9` | Switch to a numbered window |
| `prefix v` | Split with a pane below |
| `prefix s` | Split with a pane to the right |
| `prefix h/j/k/l` | Navigate panes |
| `prefix H/J/K/L` | Resize by five cells |
| `prefix M-h/j/k/l` | Resize by one cell |

### Popups and copy mode

| Key | Action |
|---|---|
| `prefix y` | Yazi file manager |
| `prefix g` | Lazygit |
| `prefix z` | Shell popup |
| `prefix e` | Open captured pane output in Helix |
| `prefix /` | Enter copy mode and search backward |
| `v` | Begin selection in copy mode |
| `y` | Copy selection |
| `prefix r` | Reload tmux configuration |

## Helix

### Navigation and editing

| Key | Action |
|---|---|
| `0` / `$` | Line start/end |
| `^` | First non-whitespace character |
| `gg` / `G` | File start/end |
| `D` | Delete to end of line |
| `V` | Select the whole line |
| `Esc` | Collapse selection |
| `==` or `+f` | Format file |
| `+w` / `+W` | Toggle/show and hide whitespace |
| `+s` | Toggle soft wrap |

### Space menu

| Key | Action |
|---|---|
| `Space q` | Quit |
| `Space e w` | Save file |
| `Space e c` | Close buffer |
| `Space e x` | Close other buffers |
| `Space e l` | Toggle LSP inlay hints |
| `Space f f` | File picker in current directory |
| `Space f F` | File picker at workspace root |
| `Space f b` | File picker in buffer directory |
| `Space f .` | Toggle git-ignore in picker |
| `Space f g` | Global search |
| `Space f e` | File explorer |
| `Space f r` | Reload all buffers |
| `Space f x` | Reset diff change |
| `Space f d` | Show Git diff in a split |

### Select mode

| Key | Action |
|---|---|
| `k` / `j` | Extend by whole lines |
| `D` | Delete selected lines |
| `Space f s` | Reflow selection to 100 characters |

## Language services

| Language | Services |
|---|---|
| Python | Ruff, basedpyright, harper-ls |
| Rust | rust-analyzer, harper-ls |
| Markdown | marksman, harper-ls |
| Nix | nil |
| YAML | yaml-language-server |
| SQL | sqlfluff |
| Cython | harper-ls |
