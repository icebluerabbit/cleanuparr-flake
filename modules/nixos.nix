{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.cleanuparr;

  defaultPackage = pkgs.callPackage ../pkgs/cleanuparr.nix {
    cleanuparr-ui = pkgs.callPackage ../pkgs/cleanuparr-ui.nix { };
    flm-qbittorrent = pkgs.callPackage ../pkgs/flm-qbittorrent.nix { };
    flm-transmission = pkgs.callPackage ../pkgs/flm-transmission.nix { };
  };

  postgres = cfg.database.postgres;
  usePostgres = cfg.database.provider == "postgres";
in
{
  options.services.cleanuparr = {
    enable = lib.mkEnableOption "Cleanuparr, a download cleaner for the Servarr ecosystem";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "pkgs.callPackage ../pkgs/cleanuparr.nix { }";
      description = "The Cleanuparr package to use.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11011;
      description = "Port the Cleanuparr HTTP server listens on.";
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address the Cleanuparr HTTP server binds to.";
    };

    basePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/cleanuparr";
      description = ''
        Base path Cleanuparr is served under. Set this when reverse proxying the UI
        on a sub-path rather than a dedicated hostname.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open {option}`services.cleanuparr.port` in the firewall.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/cleanuparr";
      description = ''
        Directory holding Cleanuparr's configuration, SQLite database and logs.
        Exported as `CLEANUPARR_CONFIG_PATH`; Cleanuparr would otherwise try to write
        into its own (read-only) Nix store path.
      '';
    };

    logsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      defaultText = lib.literalExpression ''"''${config.services.cleanuparr.dataDir}/logs"'';
      description = "Directory for Cleanuparr's log files. Defaults to `logs` under {option}`dataDir`.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "cleanuparr";
      description = "User account under which Cleanuparr runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "cleanuparr";
      description = "Group under which Cleanuparr runs.";
    };

    database = {
      provider = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
        default = "sqlite";
        description = "Database backend. SQLite lives under {option}`dataDir`.";
      };

      postgres = {
        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "PostgreSQL host.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 5432;
          description = "PostgreSQL port.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "cleanuparr";
          description = "PostgreSQL user.";
        };

        database = lib.mkOption {
          type = lib.types.str;
          default = "cleanuparr";
          description = "PostgreSQL database name.";
        };

        passwordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/secrets/cleanuparr-postgres";
          description = ''
            Path to an environment file containing the PostgreSQL password, e.g.

            ```
            POSTGRES_PASS=hunter2
            ```

            Passed to the unit as an `EnvironmentFile`, so the secret never enters the
            world-readable Nix store.
          '';
        };

        extraParams = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "SSL Mode=Require";
          description = "Extra parameters appended to the PostgreSQL connection string.";
        };
      };
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''{ TZ = "Europe/Bucharest"; }'';
      description = "Additional environment variables for the Cleanuparr service.";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Extra environment files to load into the service (for secrets).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          usePostgres
          -> postgres.passwordFile != null || cfg.environmentFiles != [ ] || cfg.environment ? POSTGRES_PASS;
        message = ''
          services.cleanuparr.database.provider is "postgres" but no source for
          POSTGRES_PASS is configured. Set one of:

            - services.cleanuparr.database.postgres.passwordFile (preferred)
            - services.cleanuparr.environmentFiles
            - services.cleanuparr.environment.POSTGRES_PASS (world-readable in the store)

          Cleanuparr treats an empty or whitespace POSTGRES_PASS as absent and throws
          `Configuration value 'POSTGRES_PASS' is required when DATABASE_PROVIDER=postgres`
          during startup, so a value is mandatory even against a `trust`-auth server —
          use any non-empty placeholder there.
        '';
      }
    ];

    systemd.services.cleanuparr = {
      description = "Cleanuparr";
      after = [ "network-online.target" ] ++ lib.optional usePostgres "postgresql.service";
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        PORT = toString cfg.port;
        BIND_ADDRESS = cfg.bindAddress;
        CLEANUPARR_CONFIG_PATH = cfg.dataDir;
        CLEANUPARR_LOGS_PATH = if cfg.logsDir != null then cfg.logsDir else "${cfg.dataDir}/logs";
        DATABASE_PROVIDER = cfg.database.provider;
        DOTNET_GCDynamicAdaptationMode = "1";
      }
      // lib.optionalAttrs (cfg.basePath != null) {
        BASE_PATH = cfg.basePath;
      }
      // lib.optionalAttrs usePostgres {
        POSTGRES_HOST = postgres.host;
        POSTGRES_PORT = toString postgres.port;
        POSTGRES_USER = postgres.user;
        POSTGRES_DB = postgres.database;
      }
      // lib.optionalAttrs (usePostgres && postgres.extraParams != null) {
        POSTGRES_EXTRA_PARAMS = postgres.extraParams;
      }
      // cfg.environment;

      serviceConfig = {
        Type = "simple";
        ExecStart = lib.getExe cfg.package;
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        EnvironmentFile =
          lib.optional (usePostgres && postgres.passwordFile != null) postgres.passwordFile
          ++ cfg.environmentFiles;
        Restart = "on-failure";
        RestartSec = "5s";

        StateDirectory = lib.mkIf (cfg.dataDir == "/var/lib/cleanuparr") "cleanuparr";
        StateDirectoryMode = "0700";

        AmbientCapabilities = [ ];
        CapabilityBoundingSet = [ ];
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # the .NET JIT needs W^X-violating mappings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        ReadWritePaths = [ cfg.dataDir ] ++ lib.optional (cfg.logsDir != null) cfg.logsDir;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 ${cfg.user} ${cfg.group} - -"
    ]
    ++ lib.optional (cfg.logsDir != null) "d ${cfg.logsDir} 0700 ${cfg.user} ${cfg.group} - -";

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    users.users = lib.mkIf (cfg.user == "cleanuparr") {
      cleanuparr = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        description = "Cleanuparr daemon user";
      };
    };

    users.groups = lib.mkIf (cfg.group == "cleanuparr") {
      cleanuparr = { };
    };
  };
}
