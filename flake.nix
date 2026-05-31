{
  description = "NixOS Baseline flake with DetSys and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # TEST: pinned 2026-04-30 tree (rev 15f4ee45), used only to source a
    # known-good kernel (6.18.26) in system/boot.nix. The 2026-05-23 bump
    # (current nixpkgs) hangs at early boot on every default kernel; the
    # 04-30 tree's 6.18.26 boots. Isolates kernel vs. the rest of the bump.
    nixpkgs-goodkernel.url =
      "github:NixOS/nixpkgs/15f4ee454b1dce334612fa6843b3e05cf546efab";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nflx-nixcfg.url = "git+ssh://git@github.com/Netflix/nflx-nixcfg";

    # Niri compositor (provides config.lib.niri.actions, required by DMS)
    #
    # BISECT (issue #111): pinned to the gen-196 (04-30) niri-flake revision,
    # which sources niri-unstable 2026-05-02-1f07cff. The 05-23 userspace bump
    # — NOT the kernel — is the boot-hang variable: gen 196 (04-30) and gen 205
    # (05-23) share the IDENTICAL 6.12.85 kernel, yet 196 boots 8/8 and 205 hangs.
    # niri (05-02 -> 05-29) is the prime suspect (compositor; fits both the DRM
    # uevent storm and the no-desktop failure). This holds niri at 04-30 while the
    # rest of the tree stays at 05-23, niri-flake still following the 05-23 nixpkgs
    # — so niri's version is the only changed variable vs. gen 205. Validate over
    # ~5 boots (the hang is intermittent). Revert to bare url once bisect concludes.
    niri-flake = {
      url = "github:sodiboo/niri-flake/945748d71d3422d4f1dada2cd10222e34ed9d767";
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

    # Fleet / Orbit agent (osquery-based host agent)
    fleet-nixos = {
      url = "git+ssh://git@github.com/alexloew/fleet-nixos";
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

          # Fleet / Orbit agent
          inputs.fleet-nixos.nixosModules.fleet-nixos

          # Netflix modules
          inputs.nflx-nixcfg.nixosModules.newt
          inputs.nflx-nixcfg.nixosModules.pulse-vpn
          inputs.nflx-nixcfg.nixosModules.ai
          inputs.nflx-nixcfg.nixosModules.metatron
          inputs.nflx-nixcfg.nixosModules.python
          inputs.nflx-nixcfg.nixosModules.git
          inputs.nflx-nixcfg.nixosModules.ssh-agent
          inputs.nflx-nixcfg.nixosModules.pulse-official
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
