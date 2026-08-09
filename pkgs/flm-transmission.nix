{
  lib,
  buildDotnetModule,
  fetchFromGitHub,
  dotnetCorePackages,
}:

# Cleanuparr's fork of Transmission.API.RPC, published upstream as the FLM.Transmission
# NuGet package on a private GitHub Packages feed. Built from source for the same reason
# as flm-qbittorrent.
buildDotnetModule (finalAttrs: {
  pname = "flm-transmission";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "Cleanuparr";
    repo = "Transmission.API.RPC";
    rev = "1d2548c3c888a2d8b0a2bf4fbefe2f91e981e263";
    hash = "sha256-JFmTyRzHN3fDdZOoeFz89fk7kroT33tceoUpVBoWS5g=";
  };

  projectFile = "Transmission.API.RPC/Transmission.API.RPC.csproj";
  nugetDeps = ./deps/flm-transmission-deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.runtime_10_0;

  useAppHost = false;
  executables = [ ];
  packNupkg = true;

  meta = {
    description = "Transmission RPC API client library (Cleanuparr fork, FLM.Transmission)";
    homepage = "https://github.com/Cleanuparr/Transmission.API.RPC";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
