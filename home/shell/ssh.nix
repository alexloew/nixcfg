{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."*" = {
      forwardAgent = false;
      addKeysToAgent = "no";
      compression = false;
      serverAliveInterval = 0;
      serverAliveCountMax = 3;
      hashKnownHosts = false;
      userKnownHostsFile = "~/.ssh/known_hosts";
      controlMaster = "no";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "no";
    };

    # Metatron checks for these sentinels to determine if it has already
    # written its config. Including them here prevents metatron from
    # trying (and failing) to write to the read-only home-manager config.
    extraConfig = ''
      ##### BEGIN METATRON AUTOCONFIG
      # Do not remove the above line. The metatron CLI uses it to update this file.
      # The Include directive was added in 7.3. IgnoreUnknown was added in 6.3. This helps prevent breaking old SSH clients that don't need nflx SSH configuration
      IgnoreUnknown Include
      Match exec "test -z $NFSSH_DISABLED"
          Include ~/.ssh/nflx_ssh.config
      # Do not remove the below line. The metatron CLI uses it to update this file.
      ##### END METATRON AUTOCONFIG
    '';
  };
}
