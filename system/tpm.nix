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

  # Add TPM2 libraries to nflx nix-ld so Metatron agent can find libtss2
  nflx.nix-ld.libraries = with pkgs; [
    tpm2-tss
  ];

  # TPM tools available system-wide
  environment.systemPackages = with pkgs; [
    tpm2-tools
    tpm2-tss

    # Metatron CLI wrapper with TPM2 libraries in the FHS env
    (pkgs.buildFHSEnv {
      name = "metatron-tpm";
      targetPkgs = pkgs: [
        tpm2-tss
        tpm2-tools
      ];
      runScript = pkgs.writeScript "metatron-tpm-run" ''
        #!/bin/sh
        exec $HOME/.config/metatron/metatron-bin "$@"
      '';
    })
  ];
}
