# Cheat Sheet

## Screenshots (Niri)

| Key | Action |
|-----|--------|
| `Super+S` | Full screen → `~/Pictures/Screenshots/` |
| `Super+Alt+S` | Region select → `~/Pictures/Screenshots/` |
| `Super+Shift+S` | Region select → clipboard |
| `Super+Shift+Alt+S` | Focused window → `~/Pictures/Screenshots/` |

---

# Tmux + Helix Cheat Sheet

## Tmux

**Prefix: `Ctrl+\`** (secondary: `Ctrl+b`)

### Windows & Panes

| Key | Action |
|-----|--------|
| `prefix c` | New window (in current path) |
| `prefix 1-9` | Switch to window by number |
| `prefix v` | Split horizontal (new pane below) |
| `prefix s` | Split vertical (new pane right) |
| `prefix h/j/k/l` | Navigate panes (left/down/up/right) |
| `prefix H/J/K/L` | Resize pane by 5 |
| `prefix M-h/j/k/l` | Resize pane by 1 |

### Popups

| Key | Action |
|-----|--------|
| `prefix y` | Open **yazi** file manager |
| `prefix g` | Open **lazygit** |
| `prefix z` | Open generic shell popup |
| `prefix e` | Capture pane output → open in Helix |

### Copy Mode

| Key | Action |
|-----|--------|
| `prefix /` | Enter copy mode, search backward |
| `v` | Begin selection |
| `y` | Copy selection |

### Other

| Key | Action |
|-----|--------|
| `prefix r` | Reload tmux config |

---

## Helix

### Navigation (Normal Mode)

| Key | Action |
|-----|--------|
| `0` | Go to line start |
| `$` | Go to line end |
| `^` | Go to first non-whitespace |
| `G` | Go to file end |
| `gg` | Go to file start |

### Editing (Normal Mode)

| Key | Action |
|-----|--------|
| `D` | Delete to end of line |
| `V` | Select whole line (visual line mode) |
| `Esc` | Collapse selection, keep primary |
| `==` | Format file |
| `+f` | Format file |
| `+w` | Toggle whitespace rendering |
| `+W` | Hide whitespace rendering |
| `+s` | Toggle soft wrap |

### Space Menu (`Space …`)

| Key | Action |
|-----|--------|
| `Space q` | Quit |
| `Space e w` | Write (save) file |
| `Space e c` | Close buffer |
| `Space e x` | Close other buffers |
| `Space e l` | Toggle LSP inlay hints |

### Space File Menu (`Space f …`)

| Key | Action |
|-----|--------|
| `Space f f` | File picker (current directory) |
| `Space f F` | File picker (workspace root) |
| `Space f b` | File picker (buffer directory) |
| `Space f .` | Toggle git-ignore in file picker |
| `Space f g` | Global search |
| `Space f e` | File explorer |
| `Space f r` | Reload all buffers |
| `Space f x` | Reset diff change |
| `Space f d` | Show git diff in new split |

### Select Mode

| Key | Action |
|-----|--------|
| `k` / `j` | Extend selection by whole lines |
| `D` | Delete selected lines |
| `Space f s` | Reflow selection to 100 chars |

---

## LSPs Active

| Language | Servers |
|----------|---------|
| Python | ruff, basedpyright, harper-ls |
| Rust | rust-analyzer, harper-ls |
| Markdown | marksman, harper-ls |
| Nix | nil |
| YAML | yaml-language-server |
| SQL | sqlfluff (formatter) |
| Cython | harper-ls |
