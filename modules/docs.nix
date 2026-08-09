{
  pkgs,
  cleanuparr,
  ...
}:

let
  # Extend pkgs with cleanuparr so the module's `package` default evaluates without
  # pulling the real build into the docs closure.
  pkgsDocs = pkgs.extend (
    _final: _prev: {
      inherit cleanuparr;
    }
  );

  nixosEval = pkgsDocs.lib.evalModules {
    modules = [
      ./nixos.nix
      {
        options.assertions = pkgsDocs.lib.mkOption {
          type = pkgsDocs.lib.types.listOf pkgsDocs.lib.types.attrs;
          default = [ ];
        };
        options.systemd = pkgsDocs.lib.mkOption {
          type = pkgsDocs.lib.types.attrs;
          default = { };
        };
        options.networking = pkgsDocs.lib.mkOption {
          type = pkgsDocs.lib.types.attrs;
          default = { };
        };
        options.users = pkgsDocs.lib.mkOption {
          type = pkgsDocs.lib.types.attrs;
          default = { };
        };
      }
    ];
    specialArgs = {
      pkgs = pkgsDocs;
    };
  };

  nixosDocs = pkgsDocs.nixosOptionsDoc {
    options = builtins.removeAttrs nixosEval.options [
      "_module"
      "assertions"
      "systemd"
      "networking"
      "users"
    ];
  };
in
pkgsDocs.runCommand "cleanuparr-options-docs" { } ''
  mkdir -p $out

  cat << 'EOF' > $out/NIXOS_OPTIONS.md
  # NixOS Module Options

  This document details the configuration options available for the Cleanuparr NixOS module.

  EOF
  sed -E \
    -e 's|\(file:///nix/store/[a-z0-9]{32}-source/|(../|g' \
    -e 's|/nix/store/[a-z0-9]{32}-source/|../|g' \
    -e 's|\\\.|\.|g' \
    ${nixosDocs.optionsCommonMark} >> $out/NIXOS_OPTIONS.md
''
