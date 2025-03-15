{
  description = "Gleamanzeigen mit Rust-Parser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rustToolchain = pkgs.rust-bin.stable.latest.default;

        # Rust-Parser bauen
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

        # Gleam-Projekt bauen
        gleamPackage = pkgs.stdenv.mkDerivation {
          pname = "gleamanzeigen";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            gleam
            erlang
            nodejs
          ];

          buildPhase = ''
            export HOME=$TMPDIR
            gleam build
          '';

          installPhase = ''
            mkdir -p $out/bin
            cat > $out/bin/gleamanzeigen <<EOF
            #!/bin/sh
            # Starte den Rust-Parser im Hintergrund
            ${rparser}/bin/rparser &
            RPARSER_PID=\$!

            # Starte die Gleam-Anwendung
            ${pkgs.erlang}/bin/erl -pa $out/build/dev/erlang/*/ebin -eval "gleamanzeigen:main([])" -noshell -s init stop

            # Beende den Rust-Parser
            kill \$RPARSER_PID
            EOF
            chmod +x $out/bin/gleamanzeigen

            # Kopiere die kompilierten Gleam-Dateien
            cp -r build $out/
          '';
        };
      in
      {
        packages = {
          rparser = rparser;
          gleamanzeigen = gleamPackage;
          default = gleamPackage;
        };

        apps.default = {
          type = "app";
          program = "${gleamPackage}/bin/gleamanzeigen";
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
