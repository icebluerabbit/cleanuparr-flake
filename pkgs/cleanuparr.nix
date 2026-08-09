{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  cleanuparr-ui,
  flm-qbittorrent,
  flm-transmission,
}:

let
  inherit (cleanuparr-ui) src version;
in
buildDotnetModule {
  pname = "cleanuparr";
  inherit src version;

  projectFile = "code/backend/Cleanuparr.Api/Cleanuparr.Api.csproj";
  nugetDeps = ./deps/cleanuparr-deps.json;

  # FLM.QBittorrent / FLM.Transmission only exist on an authenticated GitHub Packages
  # feed. Building them here and passing them as project references puts their nupkgs
  # into the local NuGet source, so `dotnet restore` never talks to that feed.
  projectReferences = [
    flm-qbittorrent
    flm-transmission
  ];

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;

  # Framework-dependent build. Upstream's Dockerfile uses PublishSingleFile, which only
  # exists to produce a one-file container image; it would force a runtime extraction
  # directory and break patchelf here for no benefit.
  selfContainedBuild = false;

  dotnetFlags = [ "-p:Version=${version}" ];

  # ReadyToRun cross-gen pulls extra restore-time packages and buys little for a
  # long-running daemon.
  dotnetBuildFlags = [ "-p:PublishReadyToRun=false" ];
  dotnetInstallFlags = [ "-p:PublishReadyToRun=false" ];

  executables = [ "Cleanuparr" ];

  # ASP.NET derives the content root from the *working directory*, so the SPA would
  # only be found when the service happens to run from the store path. Pin the web
  # root explicitly instead.
  makeWrapperArgs = [
    "--set-default"
    "ASPNETCORE_WEBROOT"
    "${placeholder "out"}/lib/cleanuparr/wwwroot"
  ];

  postInstall = ''
    mkdir -p $out/lib/cleanuparr/wwwroot
    cp -r ${cleanuparr-ui}/. $out/lib/cleanuparr/wwwroot/
  '';

  passthru = {
    ui = cleanuparr-ui;
    inherit flm-qbittorrent flm-transmission;
  };

  meta = {
    description = "Advanced download manager for the Servarr ecosystem";
    homepage = "https://github.com/Cleanuparr/Cleanuparr";
    changelog = "https://github.com/Cleanuparr/Cleanuparr/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    mainProgram = "Cleanuparr";
    platforms = lib.platforms.linux;
  };
}
