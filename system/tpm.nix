# TPM2 Configuration
# Trusted Platform Module support for device attestation and crypto
# https://nixos.wiki/wiki/TPM

{ config, pkgs, ... }:

{
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;              # PKCS#11 interface
    tctiEnvironment.enable = true;     # Set TPM2TOOLS_TCTI env var
    abrmd.enable = true;               # Access Broker and Resource Manager
  };

  # Grant tss group access to /dev/tpm0 (needed by Metatron)
  services.udev.extraRules = ''
    KERNEL=="tpm0", MODE="0660", GROUP="tss"
  '';

  # TPM tools available system-wide
  environment.systemPackages = with pkgs; [
    tpm2-tools
  ];
}
