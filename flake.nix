{
  description = "gleamanzeigen flake";

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
            ${rparser}/bin/rparser &
            RPARSER_PID=\$!

            ${pkgs.erlang}/bin/erl -pa $out/build/dev/erlang/*/ebin -eval "gleamanzeigen:main([])" -noshell -s init stop

            kill \$RPARSER_PID
            EOF
            chmod +x $out/bin/gleamanzeigen

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
