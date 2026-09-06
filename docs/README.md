# Documentation

## For operators

1. [`operations.md`](operations.md) — inspect, build, activate, update inputs and recover safely.
2. [`desktop.md`](desktop.md) — understand display, workspace, application and lid behavior.
3. [`cheatsheet.md`](cheatsheet.md) — look up interactive keybindings.

## For contributors

1. [`architecture.md`](architecture.md) — choose the correct module and understand configuration boundaries.
2. [`development.md`](development.md) — use the shell, editor, containers and virtual machines.
3. [`operations.md`](operations.md) — verify and publish configuration changes.

## Documentation ownership

Keep high-level orientation and safe first commands in the repository [`README`](../README.md). Put feature-specific behavior in the guide that owns it:

| Topic | Guide |
|---|---|
| Build, switch, rollback, lock updates, GC | `operations.md` |
| Flake and module structure | `architecture.md` |
| Niri, DMS, outputs, workspaces and lid behavior | `desktop.md` |
| Shell, editor, containers, Go and virtualization | `development.md` |
| Key combinations | `cheatsheet.md` |

When behavior changes, update the relevant guide in the same pull request. Prefer links over copying the same command or table into several documents.
