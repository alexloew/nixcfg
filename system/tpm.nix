# TPM2 Configuration
# Trusted Platform Module support for device attestation and crypto
# https://nixos.wiki/wiki/TPM

{ config, pkgs, lib, ... }:

{
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;              # PKCS#11 interface
    # Do NOT enable tctiEnvironment: it sets TPM2TOOLS_TCTI=device:/dev/tpmrm0
    # which metatron-cli cannot parse (nflxaccess-go TCTI bug). Leave unset so
    # metatron falls back to its hardcoded /dev/tpmrm0 default.
  };

  # Grant tss group access to /dev/tpm0
  services.udev.extraRules = ''
    KERNEL=="tpm0", MODE="0660", GROUP="tss"
  '';

  # After running `metatron enroll`, remove conflicting files before nixos-rebuild switch:
  #   rm ~/.config/systemd/user/metatron-agent.service
  #   rm ~/.config/systemd/user/default.target.wants/metatron-agent.service
  # See: Netflix/Issues/nix-findings/metatron-enroll-homemgr-conflict.md
  environment.systemPackages = with pkgs; [
    tpm2-tools
  ];
}
