{
  description = "OmniOS - AI Native OS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk.url = "github:nix-community/naersk/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixos-generators, naersk, flake-utils, ... }:

    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };

      # Budujemy VM tylko dla x86_64-linux
      vm-for-x86_64 = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "vm";
        modules = [ ./configuration.nix ];
      };

    in {
      packages = {
        # Oryginalne pakiety tylko dla x86_64-linux
        x86_64-linux.run-vm = vm-for-x86_64;
        x86_64-linux.install-iso = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "install-iso";
          modules = [ ./configuration.nix ];
        };

        # Nowy pakiet działający na KAŻDYM systemie (w tym aarch64-darwin)
        run-vm-cross = pkgs.writeScriptBin "run-omnios-vm" ''
          #!${pkgs.runtimeShell}

          # Ścieżka do zbudowanego skryptu VM (z x86_64-linux)
          VM_SCRIPT=${vm-for-x86_64}/bin/run-nixos-vm

          if [ ! -f "$VM_SCRIPT" ]; then
            echo "VM nie jest jeszcze zbudowana. Buduję teraz (to może potrwać)..."
            ${pkgs.nix}/bin/nix build ${self}#packages.x86_64-linux.run-vm --extra-experimental-features "nix-command flakes"
            VM_SCRIPT=./result/bin/run-nixos-vm
          fi

          echo "Uruchamiam OmniOS VM przez QEMU..."
          exec "$VM_SCRIPT" "$@"
        '';

        # Domyślny pakiet/app na wszystkich platformach
        default = self.packages.${system}.run-vm-cross;
      };

      apps = {
        default = {
          type = "app";
          program = "${self.packages.${system}.run-vm-cross}/bin/run-omnios-vm";
        };

        run-vm = self.apps.${system}.default;
      };
    });
}