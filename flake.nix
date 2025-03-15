{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-gleam.url = "github:arnarg/nix-gleam";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nix-gleam,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nix-gleam.overlays.default
            rust-overlay.overlays.default
          ];
        };

        rparser = pkgs.rustPlatform.buildRustPackage {
          pname = "rparser";
          version = "0.1.0";
          src = ./rparser;

          cargoLock = {
            lockFile = ./rparser/Cargo.lock;
            allowBuiltinFetchGit = true;
          };

          buildInputs = [ pkgs.openssl ];
          nativeBuildInputs = [ pkgs.pkg-config ];
        };

        gleam-app = pkgs.buildGleamApplication {
          src = ./.;
        };

      in
      {
        packages = rec {
          inherit rparser;

          default =
            pkgs.runCommand "gleam-app-with-rparser"
              {
                nativeBuildInputs = [ pkgs.makeWrapper ];
              }
              ''
                mkdir -p $out/bin
                cp ${gleam-app}/bin/* $out/bin/

                for bin in $out/bin/*; do
                  wrapProgram "$bin" \
                    --prefix PATH : ${pkgs.lib.makeBinPath [ rparser ]} \
                    --run "rparser --daemonize" \
                    --run "sleep 1"
                done
              '';
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.gleam
            pkgs.rustc
            pkgs.cargo
            rparser
          ];
        };
      }
    );
}
