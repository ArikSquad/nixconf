{
  description = "Small NixOS Hyprland/Caelestia starter config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hytale-launcher = {
      url = "github:JPyke3/hytale-launcher-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "ari";
      hostname = "nixbox";
      overlay = final: prev: {
        chatgpt = final.callPackage ./pkgs/chatgpt.nix { };
        mojangles = final.callPackage ./pkgs/mojangles.nix { };
        t3code = final.callPackage ./pkgs/t3code.nix { };
      };
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };
      caelestiaCli =
        inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default.overridePythonAttrs
          (old: {
            # The upstream top-level variable is not exported with structured attrs.
            preBuild = (old.preBuild or "") + ''
              export SETUPTOOLS_SCM_PRETEND_VERSION=1
            '';
          });
      caelestiaShell = inputs.caelestia-shell.packages.${system}.with-cli.override {
        caelestia-cli = caelestiaCli;
        extraRuntimeDeps = [ pkgs.libnotify ];
      };
    in
    {
      overlays.default = overlay;

      packages.${system} = {
        caelestia-cli = caelestiaCli;
        caelestia-island = import ./pkgs/caelestia-island.nix {
          upstream = caelestiaShell;
          design = ./config/caelestia/island;
          # Inter is the packaged fallback for Apple's SF Pro UI metrics.
          font = "${pkgs.inter}/share/fonts/truetype/InterVariable.ttf";
        };
        chatgpt = pkgs.chatgpt;
        mojangles = pkgs.mojangles;
        t3code = pkgs.t3code;
        default = pkgs.t3code;
      };

      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs username hostname;
        };
        modules = [
          ./hosts/${hostname}/configuration.nix
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [ overlay ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs username hostname;
            };
            home-manager.users.${username} = import ./home/${username}.nix;
          }
        ];
      };
    };
}
