{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_26,
}:

let
  pname = "cleanuparr";
  version = "2.10.3";

  src = fetchFromGitHub {
    owner = "Cleanuparr";
    repo = "Cleanuparr";
    rev = "v${version}";
    hash = "sha256-ViLvjKItlgvE77aVUmUt1LNofHpPlDoGDZl1Dn2EiZQ=";
  };
in
buildNpmPackage {
  pname = "${pname}-ui";
  inherit version src;

  # The Angular workspace lives in a subdirectory of the monorepo.
  sourceRoot = "${src.name}/code/frontend";

  nodejs = nodejs_26;

  npmDepsHash = "sha256-HVA869ahw3PS9/a9JLhHS8KieioHAdRYjp2U47WcmVU=";

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
