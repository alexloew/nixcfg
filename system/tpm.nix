# TPM2 Configuration
# Trusted Platform Module support for device attestation and crypto
# https://nixos.wiki/wiki/TPM

{ config, pkgs, lib, ... }:

{
  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;              # PKCS#11 interface
  };

  # Grant tss group access to /dev/tpm0
  services.udev.extraRules = ''
    KERNEL=="tpm0", MODE="0660", GROUP="tss"
  '';

  environment.systemPackages = with pkgs; [
    tpm2-tools
  ];
}
