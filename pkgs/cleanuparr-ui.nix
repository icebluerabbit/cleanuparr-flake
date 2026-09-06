{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_26,
}:

let
  pname = "cleanuparr";
  version = "2.10.5";

  src = fetchFromGitHub {
    owner = "Cleanuparr";
    repo = "Cleanuparr";
    rev = "v${version}";
    hash = "sha256-jaBAT3DWbsE5upQD4rERUVW/sb5Hu8pyuY7RdvhVDMs=";
  };
in
buildNpmPackage {
  pname = "${pname}-ui";
  inherit version src;

  # The Angular workspace lives in a subdirectory of the monorepo.
  sourceRoot = "${src.name}/code/frontend";

  nodejs = nodejs_26;

  npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

  # `ng build` writes to dist/ui/browser (Angular application builder layout).
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/ui/browser/. $out/
    runHook postInstall
  '';

  # The whole point of this derivation is the static bundle; keep the src/version
  # visible so the backend derivation can reuse them.
  passthru = { inherit src version; };

  meta = {
    description = "Angular web UI for Cleanuparr";
    homepage = "https://github.com/Cleanuparr/Cleanuparr";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
}
