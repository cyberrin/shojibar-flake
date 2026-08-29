{
  description = "Shoji Bar 2 - AGS (Astal + GTK4) desktop shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    shoji-bar-src = {
      url = "github:eitaar/shoji-bar-2";
      flake = false;
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, shoji-bar-src, ags }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in
  {
    packages = forAllSystems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;
        agsPkgs = ags.packages.${system};

        astalPackages = with agsPkgs; [
          io
          astal4
          apps
          battery
          network
          notifd
          mpris
          wireplumber
          powerprofiles
          tray
        ];

        runtimeDeps = with pkgs; [
          bash
          coreutils
          networkmanager
          bluez
          util-linux
          brightnessctl
          cliphist
          wl-clipboard
          imagemagick
        ];
      in
      {
        default = self.packages.${system}.shoji-bar-2;

        shoji-bar-2 = pkgs.stdenv.mkDerivation {
          pname = "shoji-bar-2";
          version = "0-unstable-${shoji-bar-src.shortRev or "dirty"}";
          src = shoji-bar-src;

          nativeBuildInputs = [
            pkgs.wrapGAppsHook4
            pkgs.gobject-introspection
            agsPkgs.default
          ];

          buildInputs = astalPackages ++ (with pkgs; [
            glib
            gjs
            gtk4
            gtk4-layer-shell
            libsoup_3
            gdk-pixbuf
            librsvg
            adwaita-icon-theme
            hicolor-icon-theme
            gsettings-desktop-schemas
            shared-mime-info
          ]);

          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/share/shoji-bar-2
            cp -r assets $out/share/shoji-bar-2/

            # THE ICON FIX.
            # SRC is an esbuild compile-time constant. ags defaults it to the
            # absolute directory of the entry file *at bundle time*, i.e. the
            # build sandbox, and the widgets load every icon from SRC/assets/*.svg
            # at runtime. Override it to point at the installed copy.
            ags bundle app.tsx $out/bin/shoji-bar-2 \
              --gtk 4 \
              -d "SRC='$out/share/shoji-bar-2'"

            runHook postInstall
          '';

          preFixup = ''
            gappsWrapperArgs+=(
              --prefix PATH : "${lib.makeBinPath runtimeDeps}"
              --set-default GTK_A11Y none
            )
          '';

          meta = {
            description = "AGS (Astal + GTK4) desktop shell, the default shell for ShojiWM";
            homepage = "https://github.com/bea4dev/shoji-bar-2";
            license = lib.licenses.mit;
            platforms = systems;
            mainProgram = "shoji-bar-2";
          };
        };
      }
    );

    devShells = forAllSystems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        default = pkgs.mkShell {
          packages = [
            (ags.packages.${system}.default.override {
              extraPackages = with ags.packages.${system}; [
                io
                astal4
                apps
                battery
                network
                notifd
                mpris
                wireplumber
                powerprofiles
                tray
              ];
            })
            pkgs.nodejs
          ];
        };
      }
    );
    nixosModules.default = { config, lib, pkgs, ... }:
    let
      cfg = config.programs.shoji-bar-2;
    in {
      options.programs.shoji-bar-2 = {
        enable = lib.mkEnableOption "the Shoji Bat 2 desktop shell";
        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
          description = "The shoji-bar-2 package to use.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package pkgs.ags ];
        services.upower.enable = lib.mkDefault true;
        services.power-profiles-daemon.enable = lib.mkDefault true;
      };
    };
  };
}
