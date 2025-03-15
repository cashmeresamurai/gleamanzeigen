{
  description = "gleamanzeigen flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    nix-gleam.url = "github:arnarg/nix-gleam";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
      nix-gleam,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          (import rust-overlay)
          nix-gleam.overlays.default
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustToolchain = pkgs.rust-bin.stable.latest.default;

        rparser = pkgs.rustPlatform.buildRustPackage {
          pname = "rparser";
          version = "0.1.0";
          src = ./rparser;
          cargoLock = {
            lockFile = ./rparser/Cargo.lock;
          };
          buildInputs = with pkgs; [ ];
          nativeBuildInputs = with pkgs; [ rustToolchain ];
        };

        gleamApp = pkgs.buildGleamApplication {
          src = ./.;
          target = "erlang";
        };

        gleamanzeigen = pkgs.writeScriptBin "gleamanzeigen" ''
          #!/bin/sh
          ${rparser}/bin/rparser &
          RPARSER_PID=$!

          ${gleamApp}/bin/gleamanzeigen

          kill $RPARSER_PID
        '';

        dockerImage = pkgs.dockerTools.buildImage {
          name = "gleamanzeigen";
          tag = "latest";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [
              gleamanzeigen
              gleamApp
              rparser
              pkgs.bash
              pkgs.coreutils
            ];
            pathsToLink = [ "/bin" ];
          };

          config = {
            Cmd = [ "${gleamanzeigen}/bin/gleamanzeigen" ];
            WorkingDir = "/";
            created = "now";
          };
        };
      in
      {
        packages = {
          rparser = rparser;
          gleamApp = gleamApp;
          gleamanzeigen = gleamanzeigen;
          docker = dockerImage;
          default = gleamanzeigen;
        };

        apps.default = {
          type = "app";
          program = "${gleamanzeigen}/bin/gleamanzeigen";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gleam
            erlang
            nodejs
            rustToolchain
            rust-analyzer
            cargo-flamegraph
          ];
        };
      }
    );
}
