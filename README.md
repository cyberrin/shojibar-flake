## A flake for [Shoji Bar 2](https://github.com/bea4dev/shoji-bar-2) with NixOS module.
Add this to your `flake.nix`:
```nix
{
  inputs = {
    shojibar = {
      url = "github:cyberrin/shojibar-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixplgs, ..your outputs.., shojibar, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # your modules
        shojibar.nixosModules.default
      ];
    };
  };
}
```
Enable in `configuration.nix`:
```nix
{ config, lib, pkgs, ... }:

{
  programs.shoji-bar-2.enable = true;
}
```
