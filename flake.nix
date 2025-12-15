{
  description = "OmniOS - AI Native OS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixos-generators, flake-utils, ... }:

    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };

      # Definicja VM tylko dla x86_64-linux
      vmPackage = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "vm";
        modules = [ ./configuration.nix ];
      };

      # Lekki skrypt działający na macOS (i innych)
      runVmScript = pkgs.writeScriptBin "run-omnios-vm" ''
        #!${pkgs.runtimeShell}

        echo "Buduję/pobieram OmniOS VM (x86_64-linux)..."
        # Buduje VM dla x86_64-linux (pobiera z cache'a jeśli możliwe)
        nix build "${self.outPath}#packages.x86_64-linux.run-vm" --extra-experimental-features "nix-command flakes"

        echo "Uruchamiam OmniOS VM przez QEMU (z HVF na Apple Silicon)..."
        # Uruchamia skrypt z wyniku builda
        ./result/bin/run-nixos-vm "$@"
      '';

    in {
      packages = {
        x86_64-linux.run-vm = vmPackage;
        x86_64-linux.install-iso = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "install-iso";
          modules = [ ./configuration.nix ];
        };

        run-vm-cross = runVmScript;
        default = runVmScript;
      };

      apps = {
        default = {
          type = "app";
          program = "${runVmScript}/bin/run-omnios-vm";
        };
      };
    });
}