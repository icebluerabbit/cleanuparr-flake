# NixOS Module Options

This document details the configuration options available for the Cleanuparr NixOS module.

## services.cleanuparr.enable



Whether to enable Cleanuparr, a download cleaner for the Servarr ecosystem.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.package



The Cleanuparr package to use.



*Type:*
package



*Default:*

```nix
pkgs.callPackage ../pkgs/cleanuparr.nix { }
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.basePath

Base path Cleanuparr is served under. Set this when reverse proxying the UI
on a sub-path rather than a dedicated hostname.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"/cleanuparr"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.bindAddress



Address the Cleanuparr HTTP server binds to.



*Type:*
string



*Default:*

```nix
"127.0.0.1"
```



*Example:*

```nix
"0.0.0.0"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.dataDir



Directory holding Cleanuparr’s configuration, SQLite database and logs.
Exported as ` CLEANUPARR_CONFIG_PATH `; Cleanuparr would otherwise try to write
into its own (read-only) Nix store path.



*Type:*
string



*Default:*

```nix
"/var/lib/cleanuparr"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.database.postgres.database



PostgreSQL database name.



*Type:*
string



*Default:*

```nix
"cleanuparr"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.database.postgres.extraParams



Extra parameters appended to the PostgreSQL connection string.



*Type:*
null or string



*Default:*

```nix
null
```



*Example:*

```nix
"SSL Mode=Require"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.database.postgres.host



PostgreSQL host.



*Type:*
string



*Default:*

```nix
"127.0.0.1"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.database.postgres.passwordFile



Path to an environment file containing the PostgreSQL password, e.g.

```
POSTGRES_PASS=hunter2
```

Passed to the unit as an ` EnvironmentFile `, so the secret never enters the
world-readable Nix store.



*Type:*
null or absolute path



*Default:*

```nix
null
```



*Example:*

```nix
"/run/secrets/cleanuparr-postgres"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.database.postgres.port



PostgreSQL port.



*Type:*
16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*

```nix
5432
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.database.postgres.user



PostgreSQL user.



*Type:*
string



*Default:*

```nix
"cleanuparr"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.database.provider



Database backend. SQLite lives under ` dataDir `.



*Type:*
one of “sqlite”, “postgres”



*Default:*

```nix
"sqlite"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.environment



Additional environment variables for the Cleanuparr service.



*Type:*
attribute set of string



*Default:*

```nix
{ }
```



*Example:*

```nix
{ TZ = "Europe/Bucharest"; }
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.environmentFiles



Extra environment files to load into the service (for secrets).



*Type:*
list of absolute path



*Default:*

```nix
[ ]
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.group



Group under which Cleanuparr runs.



*Type:*
string



*Default:*

```nix
"cleanuparr"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.logsDir



Directory for Cleanuparr’s log files. Defaults to ` logs ` under ` dataDir `.



*Type:*
null or string



*Default:*

```nix
"${config.services.cleanuparr.dataDir}/logs"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.openFirewall



Whether to open ` services.cleanuparr.port ` in the firewall.



*Type:*
boolean



*Default:*

```nix
false
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.port



Port the Cleanuparr HTTP server listens on.



*Type:*
16 bit unsigned integer; between 0 and 65535 (both inclusive)



*Default:*

```nix
11011
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)



## services.cleanuparr.user



User account under which Cleanuparr runs.



*Type:*
string



*Default:*

```nix
"cleanuparr"
```

*Declared by:*
 - [../modules/nixos.nix](../modules/nixos.nix)


