# TPM2 Configuration
# Trusted Platform Module support for device attestation and crypto
# https://nixos.wiki/wiki/TPM

{ config, pkgs, lib, ... }:

{
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;              # PKCS#11 interface
    tctiEnvironment.enable = true;     # Set TPM2TOOLS_TCTI env var
    abrmd.enable = true;               # Access Broker and Resource Manager
  };

  # Metatron treats TPM2TOOLS_TCTI as a literal file path rather than
  # parsing the TCTI "device:/dev/tpmrm0" connection string format
  environment.variables.TPM2TOOLS_TCTI = lib.mkForce "/dev/tpmrm0";

  # Grant tss group access to /dev/tpm0
  services.udev.extraRules = ''
    KERNEL=="tpm0", MODE="0660", GROUP="tss"
  '';

  environment.systemPackages = with pkgs; [
    tpm2-tools
  ];
}
