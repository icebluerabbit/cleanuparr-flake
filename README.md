# Cleanuparr Nix Flake

[![CI](https://github.com/icebluerabbit/cleanuparr-flake/actions/workflows/ci.yml/badge.svg)](https://github.com/icebluerabbit/cleanuparr-flake/actions/workflows/ci.yml)
[![Dependency Updates](https://github.com/icebluerabbit/cleanuparr-flake/actions/workflows/flake-update.yml/badge.svg)](https://github.com/icebluerabbit/cleanuparr-flake/actions/workflows/flake-update.yml)
[![Cachix Cache](https://img.shields.io/badge/Cachix-icebluerabbit--cleanuparr--flake-blue.svg)](https://icebluerabbit-cleanuparr-flake.cachix.org)
[![Nix Built](https://img.shields.io/badge/Nix-Flake-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)

This repository provides a Nix Flake for [**Cleanuparr**](https://github.com/Cleanuparr/Cleanuparr) (an advanced download cleaner for the Servarr ecosystem), built entirely from source — no Docker image, no vendored binaries — plus a NixOS service module.

---

## 📚 Documentation

*   [**NixOS Options (`docs/NIXOS_OPTIONS.md`)**](docs/NIXOS_OPTIONS.md): Configuration options for the NixOS system service module.

---

## ✨ Key Features

*   **Built from source, end to end**: The Angular UI (`buildNpmPackage`) and the .NET 10 ASP.NET backend (`buildDotnetModule`) are compiled from the tagged upstream release and stitched together — the UI lands in the backend's `wwwroot`.
*   **No authenticated NuGet feed**: Cleanuparr depends on `FLM.QBittorrent` and `FLM.Transmission`, which upstream publishes only to a private GitHub Packages feed. Their *sources* are public forks, so this flake builds both as nupkgs and injects them via `projectReferences`. Restore never touches `nuget.pkg.github.com`.
*   **Framework-dependent, not single-file**: Upstream's `PublishSingleFile=true` exists to make a slim container image. Dropping it removes the runtime extraction directory and the patchelf problems that come with it.
*   **Store-safe configuration**: Cleanuparr defaults its config directory to the directory next to its own binary — read-only under Nix. The module pins `CLEANUPARR_CONFIG_PATH` (and the web root) so state goes to `dataDir` instead.
*   **SQLite or PostgreSQL**: Declarative database selection, with the Postgres password supplied at runtime from an `EnvironmentFile` rather than the world-readable Nix store.

---

## ❄️ Nix Integration

Add Cleanuparr to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    cleanuparr-flake.url = "github:icebluerabbit/cleanuparr-flake";
  };
}
```

### NixOS Module

```nix
{ inputs, ... }:
{
  imports = [ inputs.cleanuparr-flake.nixosModules.default ];

  services.cleanuparr = {
    enable = true;
    port = 11011;
    bindAddress = "0.0.0.0";
    openFirewall = true;
  };
}
```

### With PostgreSQL

```nix
{ inputs, ... }:
{
  imports = [ inputs.cleanuparr-flake.nixosModules.default ];

  services.cleanuparr = {
    enable = true;

    database = {
      provider = "postgres";
      postgres = {
        host = "127.0.0.1";
        port = 5432;
        user = "cleanuparr";
        database = "cleanuparr";
        # File contents: POSTGRES_PASS=...
        passwordFile = "/run/secrets/cleanuparr-postgres";
      };
    };
  };
}
```

### Behind a reverse proxy on a sub-path

```nix
services.cleanuparr = {
  enable = true;
  basePath = "/cleanuparr";
};
```

### Just the package

```nix
environment.systemPackages = [ inputs.cleanuparr-flake.packages.${pkgs.system}.cleanuparr ];
```

---

## 📦 Packages

| Attribute | What it is |
| --- | --- |
| `cleanuparr` (`default`) | The full application: ASP.NET backend with the built UI in `wwwroot`. |
| `cleanuparr-ui` | Just the compiled Angular bundle. |
| `flm-qbittorrent` | `FLM.QBittorrent` 1.0.3 nupkg, built from `Cleanuparr/qbittorrent-net-client`. |
| `flm-transmission` | `FLM.Transmission` 1.0.3 nupkg, built from `Cleanuparr/Transmission.API.RPC`. |
| `docs` | Generated `NIXOS_OPTIONS.md`. |

---

## 🔄 Updating

```bash
nix run .#update-package          # bump version + all hashes and lockfiles
nix run .#generate-docs           # refresh docs/NIXOS_OPTIONS.md
nix flake check -L                # build everything + run the NixOS VM test
```

`update-package` regenerates three things that cannot be computed by evaluation alone:

*   `pkgs/cleanuparr-ui.nix` → `npmDepsHash`
*   `pkgs/deps/cleanuparr-deps.json` → the NuGet lockfile for the backend
*   `pkgs/deps/flm-*.json` → the NuGet lockfiles for the two forks (only when their pinned revisions change)

---

## 🔎 Notes & Caveats

*   **The FLM forks are pinned to commits, not tags** — neither fork publishes tags. Both are at `<Version>1.0.3</Version>`, matching the `PackageReference` versions in `Cleanuparr.Infrastructure`. If upstream bumps those references, the pins in `pkgs/flm-*.nix` must be moved too.
*   **`PublishReadyToRun` is disabled.** Upstream enables it for container images; it inflates restore and buys little for a long-lived daemon.
*   **Apprise is not bundled.** The upstream image ships an Apprise virtualenv. If you use Apprise notifications, add `pkgs.apprise` to the service's `path` yourself.
*   **`x86_64-linux` / `aarch64-linux` only.** `buildDotnetModule` needs a runtime identifier, and the service module is NixOS-specific.

---

## 📄 License

The flake is MIT. Cleanuparr itself is GPL-3.0.
