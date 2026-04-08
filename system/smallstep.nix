# Smallstep - certificate/identity tooling (work)
# Packages sourced from github:smallstep/nur

{ pkgs, inputs, ... }:

let
  stepAgentPkg = inputs.smallstep-nur.packages.${pkgs.system}.step-agent;
in
{
  environment.systemPackages = [ stepAgentPkg ];

  users.groups.step-agent = {};
  users.users.step-agent = {
    isSystemUser = true;
    group = "step-agent";
    home = "/var/lib/step-agent";
  };

  systemd.services.step-agent = {
    description = "Smallstep Agent";
    documentation = [ "https://u.step.sm/docs/agent" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    unitConfig.ConditionPathIsReadWrite = "/etc/step-agent/agent.yaml";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "step-agent";
      Group = "step-agent";
      ConfigurationDirectory = "step-agent";
      RuntimeDirectory = "step-agent";
      StateDirectory = "step-agent";
      Type = "notify";
      WatchdogSec = "60s";

      ProtectSystem = true;
      ProtectHome = "read-only";
      PrivateTmp = true;
      SecureBits = "keep-caps";
      AmbientCapabilities = "CAP_IPC_LOCK CAP_CHOWN CAP_DAC_OVERRIDE CAP_FOWNER";
      CapabilityBoundingSet = "CAP_SYSLOG CAP_IPC_LOCK CAP_CHOWN CAP_DAC_OVERRIDE CAP_FOWNER";

      ExecStart = "${stepAgentPkg}/bin/step-agent start";
      ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";

      Environment = "HOME=/var/lib/step-agent";
      DeviceAllow = "/dev/tpmrm0 rw";
      ReadWritePaths = "-/dev/tpmrm0";

      LimitNOFILE = 65536;
      LimitMEMLOCK = "infinity";

      Restart = "always";
      RestartSec = 10;
    };
  };
}
