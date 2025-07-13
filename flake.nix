{
  description = "caelestia-shell flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-cli = {
      url = "github:onbernard/caelestia-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {self, ...}:
    with inputs;
      flake-utils.lib.eachDefaultSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          overlay = [];
        };
        enhanced-beat-detector = pkgs.stdenv.mkDerivation {
          pname = "enhanced-beat-detector";
          version = "1.0";

          src = ./assets/beat_detector.cpp;
          dontUnpack = true;

          buildInputs = with pkgs; [
            pipewire
            aubio
          ];

          nativeBuildInputs = with pkgs; [pkg-config];

          CXXFLAGS = [
            "-std=c++17"
            "-O3"
            "-Wall"
            "-Wextra"
          ];

          installPhase = ''
            mkdir -p $out/bin
            g++ $CXXFLAGS \
                -I${pkgs.pipewire.dev}/include/pipewire-0.3 \
                -I${pkgs.pipewire.dev}/include/spa-0.2 \
                -I${pkgs.aubio}/include/aubio \
                -L${pkgs.pipewire}/lib \
                -L${pkgs.aubio}/lib \
                -lpipewire-0.3 -laubio -pthread \
                -o $out/bin/beat_detector \
                $src
          '';
        };
        caelestia-shell = pkgs.stdenv.mkDerivation {
          pname = "caelestia-shell";
          version = "1.0";

          nativeBuildInputs = with pkgs; [
            kdePackages.wrapQtAppsHook
            makeWrapper
            qt6.qtbase
          ];

          src = ./.;

          installPhase = ''
            mkdir -p $out/caelestia
            cp -r assets $out/caelestia
            cp -r config $out/caelestia
            cp -r modules $out/caelestia
            cp -r services $out/caelestia
            cp -r utils $out/caelestia
            cp -r widgets $out/caelestia
            cp shell.qml $out/caelestia

            mkdir $out/caelestia/bin
            cp run.fish $out/caelestia/bin/run.fish
            chmod +x $out/caelestia/bin/run.fish
            wrapProgram $out/caelesita/bin/run.fish \
              --prefix PATH : ${pkgs.lib.makeBinPath [
              inputs.quickshell.packages.${system}.default
              inputs.caelestia-cli.packages.${system}.caelestia-cli
              enhanced-beat-detector
              pkgs.papirus-icon-theme
              pkgs.dbus
              pkgs.ddcutil # Monitor settings
              pkgs.brightnessctl # Monitor settings
              pkgs.app2unit # Applications desktop entries
              pkgs.cava # Audio visualizer
              pkgs.curl # For api calls like weather stuff
              pkgs.bluez # Bluetooth
              pkgs.lm_sensors # System usage
              # For scripts
              pkgs.bash
              pkgs.fishMinimal
              pkgs.coreutils
              pkgs.findutils
              pkgs.gawk
            ]}
          '';
        };
      in {
        packages = {
          default = caelestia-shell;
          caelestia-shell = caelestia-shell;
          enhanced-beat-detector = enhanced-beat-detector;
        };
        devShell = pkgs.mkShell {
          packages = [];
          shellHook = ''
            echo "uwu"
          '';
        };
      });
}
