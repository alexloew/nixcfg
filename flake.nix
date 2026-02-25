{
  description = "NixOS Baseline flake with DetSys and Home Manager";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nflx-nixcfg.url = "git+ssh://git@github.com/Netflix/nflx-nixcfg";

    # Cursor editor
    cursor.url = "github:alexloew/cursor-nixos-flake";

    # Dank Material Shell - Wayland desktop shell
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # dgop - System monitoring for DMS
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, determinate, fh, home-manager, dms, dgop, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs-unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs pkgs-unstable; };
      modules = [
        # Host configuration (branches to system modules)
        ./hosts/nixos

        # Determinate Systems Nix
        determinate.nixosModules.default
        { environment.systemPackages = [ fh.packages.x86_64-linux.default ]; }

        # Home Manager
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs pkgs-unstable; };
          home-manager.users.alexloewenthal = import ./home;
        }

        # Netflix modules
        inputs.nflx-nixcfg.nixosModules.pulse-vpn
        inputs.nflx-nixcfg.nixosModules.sddm-themes
        inputs.nflx-nixcfg.nixosModules.metatron
        {
          nflx = {
            username = "alexloewenthal";
          };
        }
      ];
    };
  };
}
