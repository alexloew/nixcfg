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

    # Allow metatron to inject nflx SSH config on enroll.
    # The Match exec guard lets nfssh disable the include when needed.
    extraConfig = ''
      IgnoreUnknown Include
      Match exec "test -z $NFSSH_DISABLED"
          Include ~/.ssh/nflx_ssh.config
    '';
  };
}
