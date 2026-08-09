{
  description = "Nix Flake for Cleanuparr (download cleaner for the Servarr ecosystem)";

  nixConfig = {
    extra-substituters = [
      "https://icebluerabbit-cleanuparr-flake.cachix.org"
    ];
    extra-trusted-public-keys = [
      "icebluerabbit-cleanuparr-flake.cachix.org-1:K0JIcbUOshVOfIpRhQSCwIl5UH34qxlnB13RDwl/p7s="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        {
          self',
          pkgs,
          ...
        }:
        {
          formatter = pkgs.nixfmt-tree;

          packages = rec {
            flm-qbittorrent = pkgs.callPackage ./pkgs/flm-qbittorrent.nix { };
            flm-transmission = pkgs.callPackage ./pkgs/flm-transmission.nix { };
            cleanuparr-ui = pkgs.callPackage ./pkgs/cleanuparr-ui.nix { };
            cleanuparr = pkgs.callPackage ./pkgs/cleanuparr.nix {
              inherit cleanuparr-ui flm-qbittorrent flm-transmission;
            };
            docs = pkgs.callPackage ./modules/docs.nix { inherit cleanuparr; };
            default = cleanuparr;
          };

          apps.generate-docs = {
            type = "app";
            program = "${pkgs.writeShellScript "generate-docs" ''
              echo "==> Generating and copying Cleanuparr options documentation..."
              mkdir -p docs
              cp -f ${self'.packages.docs}/NIXOS_OPTIONS.md docs/NIXOS_OPTIONS.md
              echo "==> Done!"
            ''}";
          };

          apps.update-package = {
            type = "app";
            program = "${pkgs.writeShellScript "update-package" ''
              export PATH="${
                pkgs.lib.makeBinPath [
                  pkgs.nix
                  pkgs.curl
                  pkgs.jq
                  pkgs.git
                  pkgs.gnused
                  pkgs.gnugrep
                  pkgs.coreutils
                ]
              }"
              ${builtins.readFile ./scripts/update-package.sh}
            ''}";
          };

          checks = {
            cleanuparr-integration-test = pkgs.testers.runNixOSTest {
              name = "cleanuparr-integration-test";

              nodes.machine =
                { ... }:
                {
                  imports = [ self.nixosModules.cleanuparr ];

                  services.cleanuparr = {
                    enable = true;
                    package = self'.packages.cleanuparr;
                  };

                  # Control startup ordering from the test script instead of at boot.
                  systemd.services.cleanuparr.wantedBy = pkgs.lib.mkForce [ ];
                };

              testScript = ''
                machine.wait_for_unit("network.target")
                machine.start_job("cleanuparr.service")
                try:
                    machine.wait_for_open_port(11011, timeout=120)
                    machine.succeed("curl -f http://127.0.0.1:11011/")
                except Exception as e:
                    machine.log(machine.succeed("journalctl -u cleanuparr.service --no-pager"))
                    raise e
              '';
            };
          };
        };

      flake = {
        nixosModules.cleanuparr = import ./modules/nixos.nix;
        nixosModules.default = self.nixosModules.cleanuparr;
      };
    };
}
