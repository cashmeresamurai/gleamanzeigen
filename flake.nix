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

        fetchHexPackage =
          {
            name,
            version,
            sha256,
          }:
          pkgs.fetchurl {
            url = "https://repo.hex.pm/tarballs/${name}-${version}.tar";
            inherit sha256;
          };

        hexPackages = {
          filepath = fetchHexPackage {
            name = "filepath";
            version = "1.1.1";
            sha256 = "sha256-ZfUQE7z3imA6/9eZLvHMbsqWx0A460iIf2Vt5E28GQI=";
          };
        };

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

          preBuildPhase = ''
            export HOME=$TMPDIR
            mkdir -p $HOME/.hex/packages

            mkdir -p $HOME/.hex/packages/filepath
            ln -sf ${hexPackages.filepath} $HOME/.hex/packages/filepath/filepath.tar
          '';

          buildPhase = ''
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

        dockerImage = pkgs.dockerTools.buildImage {
          name = "gleamanzeigen";
          tag = "latest";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [
              gleamPackage
              rparser
              pkgs.erlang
              pkgs.bash
              pkgs.coreutils
            ];
            pathsToLink = [
              "/bin"
              "/build"
            ];
          };

          config = {
            Cmd = [ "${gleamPackage}/bin/gleamanzeigen" ];
            WorkingDir = "/";
            created = "now";
          };
        };
      in
      {
        packages = {
          rparser = rparser;
          gleamanzeigen = gleamPackage;
          docker = dockerImage;
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
