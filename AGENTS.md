# Repository guardrails

## Source of truth

- Use `/home/alexloewenthal/gh-personal/nixcfg` as the authoritative repository and flake.
- Never edit, update, evaluate, build, or activate `/etc/nixos`.
- Preserve unrelated user work. Never reset, restore, clean, or overwrite changes that the agent did not create.
- Never stage `.agent-beach/` or unrelated files.

## Builds and realisation

Never run a Nix command that may evaluate the complete system, fetch inputs, download or build a closure, realise store paths, or activate a configuration without asking first. This includes, but is not limited to:

- `nix build`
- `nix flake check`
- full-system `nix eval` commands that may trigger input fetching or import-from-derivation
- `nh os build`, `nh os test`, and `nh os switch`
- `nixos-rebuild` in any mode
- `home-manager build` and `home-manager switch`
- project `nix run` apps that build or activate a configuration

These commands can be slow, download large closures, consume substantial disk space, require privilege elevation, or modify the running and booted system.

Before running one, provide:

1. The exact command.
2. Whether it is evaluation-only, build-only, temporary activation, permanent activation, or boot configuration.
3. Whether it uses `sudo` or another elevation mechanism.
4. The expected impact, including potentially large downloads or builds.

Wait for explicit approval of that exact command. Approval is single-use and does not authorize retries with materially different flags, another build, activation, reboot, or garbage collection.

## Preferred commands after approval

This repository does not currently provide a `.#switch` flake app. Do not invent or assume `nix run .#switch`.

Use the least-impactful command that satisfies the approved action:

```bash
# Build only; do not activate
nh os build /home/alexloewenthal/gh-personal/nixcfg#nixos

# Temporarily activate; do not make it the boot default
nh os test /home/alexloewenthal/gh-personal/nixcfg#nixos

# Permanently activate and update the boot default
nh os switch /home/alexloewenthal/gh-personal/nixcfg#nixos
```

Build approval authorizes only the build command. `test` and `switch` require separate, explicit activation approval. Propose any deviation from the preferred command in the same approval request.

## Checks allowed without build approval

The following local, non-realising checks are allowed:

- Reading and searching repository files.
- `git status`, `git diff`, and `git diff --check`.
- `jq empty flake.lock` and lock-file comparison.
- Syntax-only parsing of edited Nix files with `nix-instantiate --parse`.
- Current package and option lookups through the Nix documentation tool.

If a supposedly read-only command begins fetching, building, or realising paths, stop it and request approval before retrying.

## Flake input updates

- Run `nix flake update` only when the user explicitly requests an input update.
- Update `/home/alexloewenthal/gh-personal/nixcfg/flake.lock`, never `/etc/nixos/flake.lock`.
- Run input updates as the user, never with `sudo`.
- Review `git diff -- flake.lock` before proposing verification.
- Do not activate an updated lock file as part of the update workflow unless separately approved.

Use `.pi/skills/nixcfg-flake-update/SKILL.md` for the routine lock-update and PR workflow.

## Activation and recovery

- Never reboot, roll back, or activate a system generation without explicit approval.
- Never treat successful evaluation or build as approval to activate.
- For a reported regression, preserve logs and old generations before proposing rollback or cleanup.
- Do not run garbage collection as part of a build or update workflow.

## Garbage collection

Never run `nix-collect-garbage`, `nix store gc`, profile-generation deletion, or store repair without explicit approval. In particular, `sudo nix-collect-garbage -d` deletes every non-current system generation regardless of age and removes normal rollback options.

The configured weekly garbage collection already deletes generations older than 30 days. Prefer that policy for routine maintenance.
