# Using lefthook with Nix

Easily manage git hooks with Nix, internally using lefthook.

## Usages

### Nix Flakes

```nix
{
  description = "An example nix flake project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    lefthook = {
      url = "github:sudosubin/lefthook.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, lefthook, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

      in
      {
        checks = {
          lefthook-check = lefthook.lib.${system}.run {
            src = ./.;
            config = {
              pre-commit.commands = {
                nixpkgs-fmt = {
                  run = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt {staged_files}";
                  glob = "*.nix";
                };
              };
            };
          };
        };

        devShell = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.lefthook-check) shellHook;
        };
      }
    );
}
```

## Credits

This project was written with a lot of influence from [pre-commit-hooks.nix](https://github.com/cachix/pre-commit-hooks.nix).
