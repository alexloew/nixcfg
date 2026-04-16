{
  description = "NixOS Baseline flake with DetSys and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nflx-nixcfg.url = "git+ssh://git@github.com/Netflix/nflx-nixcfg";

    # Niri compositor (provides config.lib.niri.actions, required by DMS)
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    # Smallstep - certificate/identity tooling (private)
    smallstep = {
      url = "git+ssh://git@github.com/alexloew/smallstep-nixos-flake";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      determinate,
      fh,
      home-manager,
      niri-flake,
      dms,
      dgop,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          # Host configuration (branches to system modules)
          ./hosts/nixos

          # Niri compositor (provides config.lib.niri.actions for DMS)
          niri-flake.nixosModules.niri

          # Determinate Systems Nix
          determinate.nixosModules.default
          { environment.systemPackages = [ fh.packages.x86_64-linux.default ]; }

          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "bak";
            home-manager.users.alexloewenthal = import ./home;
          }

          # Smallstep step-agent
          inputs.smallstep.nixosModules.default

          # Netflix modules
          inputs.nflx-nixcfg.nixosModules.newt
          inputs.nflx-nixcfg.nixosModules.pulse-vpn
          inputs.nflx-nixcfg.nixosModules.ai
          inputs.nflx-nixcfg.nixosModules.metatron
          inputs.nflx-nixcfg.nixosModules.python
          inputs.nflx-nixcfg.nixosModules.git
          inputs.nflx-nixcfg.nixosModules.ssh-agent
          {
            nflx = {
              username = "alexloewenthal";
              nix-ld.enable = true;
              ssh-agent.enable = true;
              vpn.pulse.browser-extensions = [];
            };
          }
        ];
      };
    };
}
