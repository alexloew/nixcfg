---
name: nixcfg-flake-update
description: Update the flake.lock in /home/alexloewenthal/gh-personal/nixcfg, verify the complete NixOS configuration, and open a GitHub pull request. Use when asked to update, refresh, or bump nixcfg flake inputs or create the routine flake-update PR.
---

# Nixcfg flake update

Update the authoritative Git checkout and publish a verified PR. Never update or build from `/etc/nixos`.

## Safety rules

- Use `/home/alexloewenthal/gh-personal/nixcfg` as the repository and flake.
- Run the lock update as the user, never with `sudo`.
- Preserve unrelated work. Do not stage `.agent-beach/` or other unrelated files.
- Do not activate, test-switch, or switch the running system unless the user separately asks.
- Do not publish a lock file that fails full NixOS evaluation.
- Use the Nix package/options lookup tool for current nixpkgs facts rather than relying on memory.
- Use the least-privileged authenticated zone needed for private inputs, push, and GitHub PR operations.

## Workflow

1. Inspect `git status`, the current branch, remotes, and recent commits.
2. Start from current `origin/main` unless the user explicitly names an existing update branch.
   - Prefer branch `chore/update-flake-inputs`.
   - If that branch contains unrelated or ambiguous work, stop and ask before resetting, deleting, or replacing it.
3. Update the authoritative lock file:

   ```bash
   nix flake update --flake /home/alexloewenthal/gh-personal/nixcfg
   ```

4. Review `flake.lock` before testing.
   - Summarize old and new revisions for every root input.
   - Note added or removed transitive inputs and unusually large graph changes.
   - Check that no credentials or unrelated files appeared.
5. Verify the update:
   - Parse any edited `.nix` files.
   - Run `git diff --check`.
   - Evaluate the complete system:

     ```bash
     nix eval --raw /home/alexloewenthal/gh-personal/nixcfg#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
     ```

   - Dry-run the same build used for deployment:

     ```bash
     nix build --dry-run --no-link /home/alexloewenthal/gh-personal/nixcfg#nixosConfigurations.nixos.config.system.build.toplevel
     ```

   - Build a targeted package when evaluation exposes a package compatibility boundary.
   - Treat warnings separately from failures; record material warnings in the PR.
6. If verification fails, diagnose the first concrete failure. Apply the smallest compatibility fix only when evidence supports it, then rerun all checks. Do not hide the failure by blindly restoring an older lock revision.
7. Stage only `flake.lock` and any intentional compatibility or skill files. Review the staged diff and ensure `.agent-beach/` remains excluded.
8. Commit with a focused message, normally:

   ```text
   chore(flake): update inputs
   ```

9. Push the branch and open a PR to `main`.

## Pull request content

Include:

- A concise summary of the update.
- A table of root inputs with abbreviated old and new revisions.
- Any required compatibility changes and their cause.
- Verification commands and concrete outcomes.
- Remaining evaluation warnings, clearly distinguished from errors.
- A note that the PR does not activate the system.

After creating the PR, verify its base, head, state, and commit list. Return the PR URL and the post-merge command:

```bash
cd /home/alexloewenthal/gh-personal/nixcfg
git switch main
git pull --ff-only
update
```
