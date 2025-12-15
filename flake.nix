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

      # Budujemy VM tylko dla x86_64-linux (do cache'a lub remote build)
      vmPackage = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "vm";
        modules = [ ./configuration.nix ];
      };

      # Skrypt uruchamiający VM – działa na KAŻDYM systemie (w tym aarch64-darwin)
      runVmScript = pkgs.writeScriptBin "run-omnios-vm" ''
        #!${pkgs.runtimeShell}

        echo "Uruchamiam OmniOS VM (x86_64) przez QEMU na ${system}..."

        # Probujemy użyć gotowego wyniku z cache'a Nix (jeśli ktoś wcześniej zbudował)
        # lub z lokalnego store, jeśli jest
        if [ -f "./result/bin/run-nixos-vm" ]; then
          exec ./result/bin/run-nixos-vm "$@"
        fi

        # Jeśli nie ma lokalnie – próbujemy pobrać z cache'a (cachix lub oficjalny)
        echo "Pobieram pre-built VM z cache'a Nix..."
        ${pkgs.nix}/bin/nix shell ${self}#packages.x86_64-linux.run-vm --impure --command run-nixos-vm "$@"
      '';

    in {
      packages = {
        # Dla x86_64-linux – oryginalne zachowanie
        x86_64-linux.run-vm = vmPackage;
        x86_64-linux.install-iso = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "install-iso";
          modules = [ ./configuration.nix ];
        };

        # Dostępne na wszystkich platformach
        run-vm-cross = runVmScript;
        default = runVmScript;
      };

      apps = {
        default = {
          type = "app";
          program = "${runVmScript}/bin/run-omnios-vm";
        };
        run-vm = self.apps.${system}.default;
      };
    });
}