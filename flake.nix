{
  description = "NixOS Baseline flake with DetSys and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nflx-nixcfg.url = "git+ssh://git@github.com/Netflix/nflx-nixcfg";

    # Niri compositor package; NixOS and Home Manager provide the modules.
    niri = {
      url = "github:niri-wm/niri";
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
      url = "git+ssh://git@github.com/Netflix/smallstep-nix";
    };

    # Fleet / Orbit agent (osquery-based host agent)
    fleetdm-nix = {
      url = "git+ssh://git@github.com/Netflix/fleetdm-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # herdr - terminal workspace manager / multiplexer for AI coding agents
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      determinate,
      fh,
      home-manager,
      niri,
      dms,
      dgop,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      niriPackage = niri.packages.${system}.niri;
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs niriPackage; };
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
            home-manager.extraSpecialArgs = { inherit inputs niriPackage; };
            home-manager.backupFileExtension = "bak";
            home-manager.users.alexloewenthal = import ./home;
          }

          # Smallstep step-agent
          inputs.smallstep.nixosModules.default

          # Fleet / Orbit agent
          inputs.fleetdm-nix.nixosModules.fleetdm-nix

          # Netflix modules
          inputs.nflx-nixcfg.nixosModules.newt
          inputs.nflx-nixcfg.nixosModules.pulse-vpn
          inputs.nflx-nixcfg.nixosModules.ai
          inputs.nflx-nixcfg.nixosModules.metatron
          inputs.nflx-nixcfg.nixosModules.python
          inputs.nflx-nixcfg.nixosModules.git
          inputs.nflx-nixcfg.nixosModules.ssh-agent
          inputs.nflx-nixcfg.nixosModules.pulse-official
          inputs.nflx-nixcfg.nixosModules.gh
          {
            nflx = {
              username = "alexloewenthal";
              nix-ld.enable = true;
              ssh-agent.enable = true;
              vpn.pulse.browser-extensions = [ ];
              vpn.pulse-official.enable = true;
              genai.disable-project-id-warning = true;
            };
          }
        ];
      };
    };
}
