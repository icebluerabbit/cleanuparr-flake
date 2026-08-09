#!/usr/bin/env bash
set -euo pipefail

UI_NIX="pkgs/cleanuparr-ui.nix"
DUMMY_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# Rebuild a package's NuGet lockfile via buildDotnetModule's fetch-deps script.
# `nix run` cannot be used here: the script is a bare file, not a bin/ directory.
regen_nuget_deps() {
    local attr="$1" out="$2"
    echo "==> Regenerating $out ..."
    local script
    script=$(nix build ".#${attr}.passthru.fetch-deps" --no-link --print-out-paths)
    "$script" "$out"
}

OLD_VERSION=$(nix eval --raw .#cleanuparr-ui.version)
echo "==> Current version: $OLD_VERSION"

echo "==> Querying latest Cleanuparr release..."
NEW_VERSION=$(curl -sSf https://api.github.com/repos/Cleanuparr/Cleanuparr/releases/latest | jq -r .tag_name)
NEW_VERSION="${NEW_VERSION#v}"
echo "==> Resolved version: $NEW_VERSION"

if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
    echo "==> Already up-to-date at version $NEW_VERSION."
    exit 0
fi

echo "==> Prefetching source tarball..."
SRC_HASH=$(nix store prefetch-file --unpack --hash-type sha256 --json \
    "https://github.com/Cleanuparr/Cleanuparr/archive/v${NEW_VERSION}.tar.gz" | jq -r .hash)
echo "==> Source hash: $SRC_HASH"

sed -i -E \
    -e "s|version = \"${OLD_VERSION}\";|version = \"${NEW_VERSION}\";|" \
    -e "s|hash = \"sha256-[^\"]*\";|hash = \"${SRC_HASH}\";|" \
    "$UI_NIX"

# npmDepsHash cannot be evaluated, only observed: force a mismatch and read it back.
echo "==> Determining new npmDepsHash..."
sed -i -E "s|npmDepsHash = \"sha256-[^\"]*\";|npmDepsHash = \"${DUMMY_HASH}\";|" "$UI_NIX"

set +e
BUILD_OUTPUT=$(nix build .#cleanuparr-ui.npmDeps --no-link 2>&1)
set -e

NEW_NPM_HASH=$(echo "$BUILD_OUTPUT" | grep -o -E 'got:[[:space:]]+sha256-[A-Za-z0-9+/=]+' | awk '{print $2}' | head -n 1)

if [ -z "$NEW_NPM_HASH" ]; then
    echo "ERROR: Failed to extract npmDepsHash from build output!"
    echo "$BUILD_OUTPUT"
    exit 1
fi

echo "==> Found npmDepsHash: $NEW_NPM_HASH"
sed -i -E "s|npmDepsHash = \"sha256-[^\"]*\";|npmDepsHash = \"${NEW_NPM_HASH}\";|" "$UI_NIX"

# The forks are pinned to commits and rarely move, but their lockfiles are cheap to
# refresh and must stay consistent with the SDK the backend restores against.
regen_nuget_deps flm-qbittorrent pkgs/deps/flm-qbittorrent-deps.json
regen_nuget_deps flm-transmission pkgs/deps/flm-transmission-deps.json
regen_nuget_deps cleanuparr pkgs/deps/cleanuparr-deps.json

echo "==> Updated Cleanuparr $OLD_VERSION -> $NEW_VERSION"
echo "==> Reminder: if code/backend/Cleanuparr.Infrastructure/*.csproj now references a"
echo "    different FLM.QBittorrent / FLM.Transmission version, move the commit pins in"
echo "    pkgs/flm-qbittorrent.nix and pkgs/flm-transmission.nix to match."
