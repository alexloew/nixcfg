{ lib, ... }:

{
  # Static SSH settings in a nix-managed include file.
  # ~/.ssh/config is intentionally NOT managed by home-manager so that
  # metatron can open it for writing during enroll.
  home.file.".ssh/nix.conf".text = ''
    Host *
      ForwardAgent no
      AddKeysToAgent no
      Compression no
      ServerAliveInterval 0
      ServerAliveCountMax 3
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no
  '';

  # Bootstrap ~/.ssh/config as a plain writable file on first activation
  # (or when a previous programs.ssh symlink is found). Metatron appends
  # its AUTOCONFIG block here; our settings live in ~/.ssh/nix.conf above.
  home.activation.sshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _ssh_config="$HOME/.ssh/config"
    if [ -L "$_ssh_config" ] || [ ! -f "$_ssh_config" ]; then
      rm -f "$_ssh_config"
      mkdir -p "$HOME/.ssh"
      chmod 700 "$HOME/.ssh"
      printf 'Include ~/.ssh/nix.conf\n' > "$_ssh_config"
      chmod 600 "$_ssh_config"
    fi
    unset _ssh_config
  '';
}
