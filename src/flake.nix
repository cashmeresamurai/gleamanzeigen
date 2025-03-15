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
            (final: prev: {
              rustToolchain = final.rust-bin.stable.latest.default;
            })
          ];
        };

        gleam-app = pkgs.buildGleamApplication {
          src = ./.;
        };

        rparser = pkgs.rustPlatform.buildRustPackage {
          pname = "rparser";
          version = "0.1.0";
          src = ./.; # Annahme: Rust-Code liegt im Root-Verzeichnis
          cargoLock.lockFile = ./Cargo.lock;

          buildInputs = [ pkgs.openssl ];
          nativeBuildInputs = [ pkgs.pkg-config ];
        };

      in
      {
        packages = rec {
          inherit rparser;

          default =
            pkgs.runCommand "gleamanzeigen"
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
                    --run "sleep 2"
                done
              '';
        };
      }
    );
}
