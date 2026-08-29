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

  outputs = { self, nixpkgs, ..your outputs.., shojibar, ... }@inputs:
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
In order for ShojiWM to automatically start the bar on the launch, in `index.tsx`, you need to change this:
```tsx
COMPOSITOR.process.once("shell", {
  command: "cd ~/.config/shoji-bar-2 && GTK_A11Y=none ags run app.tsx",
  runPolicy: "once-per-session",
});
```
into this:
```tsx
COMPOSITOR.process.once("shell", {
  command: "shoji-bar-2",
  runPolicy: "once-per-session",
});
```
