# Backport the platform-specific OpenCode 2.2.5 dependency hashes from:
# https://github.com/NixOS/nixpkgs/commit/c399e1b7fb90789e3e032784ef8ad98ba9907169
# The Linux hash matches the output observed during the local failed build.
# opencode-desktop inherits opencode.node_modules, so this fixes both packages.
# Remove once the pinned nixpkgs includes the upstream fix. The version and
# original-hash guards leave newer or already-corrected packages unchanged.
_final: prev:
{
  opencode = prev.opencode.overrideAttrs (
    old:
    prev.lib.optionalAttrs (
      old.version == "2.2.5"
      && old.node_modules.outputHash == "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc="
    ) {
      node_modules = old.node_modules.overrideAttrs (_: {
        outputHash =
          if prev.stdenv.hostPlatform.isLinux then
            "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA="
          else if prev.stdenv.hostPlatform.isDarwin then
            "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc="
          else
            throw "Unsupported platform";
      });
    }
  );
}
