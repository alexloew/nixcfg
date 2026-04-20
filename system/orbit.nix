# Fleet / Orbit agent
# Host agent that enrolls with a Fleet (osquery) server.
#
# The enroll secret is read from a file outside the repo so it doesn't land
# in the public flake. Provision it once out-of-band:
#
#   sudo install -d -m 0700 /etc/fleet
#   sudo install -m 0600 /dev/stdin /etc/fleet/enroll-secret <<< 'THE_SECRET'
#
# If the file is missing at activation time, orbit will fail to start.

{ config, pkgs, ... }:

{
  services.orbit = {
    enable = true;
    fleetUrl = "https://dnrfleet-endpoint.test.netflix.net";
    enrollSecretPath = "/etc/fleet/enroll-secret";
    debug = true;
    devMode = false;
    hostIdentifier = "uuid";
    enableScripts = false;
    fleetCertificate = "/etc/ssl/certs/ca-bundle.crt";
    fleetDesktopAlternativeBrowserHost = null;
    fleetManagedHostIdentityCertificate = false;
    endUserEmail = null;
    insecure = false;
  };
}
