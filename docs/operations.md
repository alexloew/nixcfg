# Operating the NixOS configuration

## Safety model

Use `/home/alexloewenthal/gh-personal/nixcfg#nixos` for every operation. `/etc/nixos` is not a working copy and must not be updated, built or activated.

Preserve rollback paths:

- inspect changes before building;
- build before activation;
- use `test` before `switch` when runtime behavior is uncertain;
- keep old generations until the replacement has booted successfully; and
- do not combine an input update with garbage collection.

## Inspect changes

```bash
cd /home/alexloewenthal/gh-personal/nixcfg
git status --short --branch
git diff --check
git diff
```

For an edited Nix file, check syntax without evaluating the system:

```bash
nix-instantiate --parse path/to/file.nix >/dev/null
```

## Build and activation levels

| Command | Effect |
|---|---|
| `nh os build …#nixos` | Builds the system closure; does not activate it |
| `nh os test …#nixos` | Builds and activates temporarily; reboot returns to the prior boot default |
| `nh os switch …#nixos` | Builds, activates and updates the boot default |

Commands:

```bash
nh os build /home/alexloewenthal/gh-personal/nixcfg#nixos
nh os test /home/alexloewenthal/gh-personal/nixcfg#nixos
nh os switch /home/alexloewenthal/gh-personal/nixcfg#nixos
```

The shell aliases are:

| Alias | Expansion |
|---|---|
| `update` | `nh os switch /home/alexloewenthal/gh-personal/nixcfg#nixos` |
| `nix-test` | `nh os test /home/alexloewenthal/gh-personal/nixcfg#nixos` |
| `flake-up` | update every input in the authoritative flake |
| `conf` | enter the authoritative checkout |

Treat `update` as a permanent activation, not as a harmless package update.

## Update flake inputs

Update one input when possible:

```bash
nix flake update dms --flake /home/alexloewenthal/gh-personal/nixcfg
```

Update the complete graph only when intended:

```bash
nix flake update --flake /home/alexloewenthal/gh-personal/nixcfg
```

Run lock updates as the normal user, never with `sudo`. Then review the complete graph change:

```bash
jq empty flake.lock
git diff -- flake.lock
git diff --check
```

A named input update can still change transitive inputs. Record every changed root input, newly added node and removed node before building.

Recommended verification sequence:

```bash
nix eval --raw \
  /home/alexloewenthal/gh-personal/nixcfg#nixosConfigurations.nixos.config.system.build.toplevel.drvPath

nix build --dry-run --no-link \
  /home/alexloewenthal/gh-personal/nixcfg#nixosConfigurations.nixos.config.system.build.toplevel

nh os build /home/alexloewenthal/gh-personal/nixcfg#nixos
```

The first command evaluates the complete configuration. The second reports fetches and builds without realizing the planned closure, although evaluation can still perform import-from-derivation work. The third performs the real build.

## Review and publish

Use a focused branch. Stage only intended files and verify the staged diff:

```bash
git switch -c chore/<change>
git add -- path/to/intended-file
git diff --cached --check
git diff --cached
git commit -m '<focused message>'
```

Do not stage `.agent-beach/` or unrelated working-tree changes. A pull request should state:

- what changed;
- which inputs moved;
- any compatibility fix;
- commands and concrete verification results;
- remaining warnings; and
- that no activation occurred, when applicable.

## Recovery

If a temporary `nh os test` activation is unhealthy, reboot to return to the prior boot default. If a switched generation does not boot, select an older generation from the systemd-boot menu.

Before changing generations manually, preserve:

```bash
nix-env --list-generations --profile /nix/var/nix/profiles/system
journalctl -b -p warning
systemctl --failed
```

Do not delete generations, run store repair or garbage-collect while diagnosing a regression.

## Garbage collection

The configuration runs weekly Nix garbage collection and deletes generations older than 30 days. It also runs weekly store optimization.

The `cleanup` shell alias expands to `sudo nix-collect-garbage -d`. It deletes every non-current system generation and removes normal rollback options. Use it only as an explicit destructive maintenance action, not as routine cleanup.

## Post-merge activation

After a configuration pull request merges:

```bash
cd /home/alexloewenthal/gh-personal/nixcfg
git switch main
git pull --ff-only
nh os build /home/alexloewenthal/gh-personal/nixcfg#nixos
```

Activate separately after reviewing the successful build:

```bash
nh os test /home/alexloewenthal/gh-personal/nixcfg#nixos
# or, when ready to update the boot default:
nh os switch /home/alexloewenthal/gh-personal/nixcfg#nixos
```
