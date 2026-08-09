{
  lib,
  buildDotnetModule,
  fetchFromGitHub,
  dotnetCorePackages,
}:

# Cleanuparr's fork of fedarovich/qbittorrent-net-client, published upstream as the
# FLM.QBittorrent NuGet package on a private GitHub Packages feed. The source is public,
# so we build the nupkg here and feed it to Cleanuparr via `projectReferences`.
buildDotnetModule (finalAttrs: {
  pname = "flm-qbittorrent";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "Cleanuparr";
    repo = "qbittorrent-net-client";
    rev = "b36a3ca40c83776f9f1b86a56e46ae718e2cf96f";
    hash = "sha256-33M+j8Phukwa5R7zo5Nuc/rSb2Dv2JYfTcXZMkFu7jw=";
  };

  projectFile = "src/QBittorrent.Client/QBittorrent.Client.csproj";
  nugetDeps = ./deps/flm-qbittorrent-deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.runtime_10_0;

  # netstandard2.1 library: no apphost, no executables, just the nupkg.
  useAppHost = false;
  executables = [ ];
  packNupkg = true;

  meta = {
    description = "qBittorrent remote API client library (Cleanuparr fork, FLM.QBittorrent)";
    homepage = "https://github.com/Cleanuparr/qbittorrent-net-client";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
