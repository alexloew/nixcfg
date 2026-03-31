{
  description = "Ubuntu 24.04 VM - repeatable lifecycle with TPM";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          libvirt      # virsh
          virt-manager # virt-install
          cloud-utils  # cloud-localds
          qemu         # qemu-img
          curl
        ];

        shellHook = ''
          echo "ubuntu-vm dev shell"
          echo "  ./create.sh   — create VM from scratch"
          echo "  ./destroy.sh  — destroy VM and disks"
        '';
      };
    };
}
