# Using lefthook with Nix

Easily manage git hooks with Nix, internally using lefthook.

## Usages

### Nix Flakes

```nix
{
  description = "An example nix flake project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    lefthook = {
      url = "github:sudosubin/lefthook.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, lefthook }:
    let
      inherit (nixpkgs.lib) genAttrs platforms;
      forAllSystems = f: genAttrs platforms.unix (system: f (import nixpkgs { inherit system; }));

    in
    {
      checks = forAllSystems (pkgs: {
        lefthook-check = lefthook.lib.${pkgs.system}.run {
          src = ./.;
          config = {
            pre-commit.commands = {
              nixpkgs-fmt = {
                run = "${pkgs.lib.getExe pkgs.nixpkgs-fmt} {staged_files}";
                glob = "*.nix";
              };
            };
          };
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inherit (self.checks.${pkgs.system}.lefthook-check) shellHook;
        };
      });
    };
}
```

## Credits

This project was written with a lot of influence from [pre-commit-hooks.nix](https://github.com/cachix/pre-commit-hooks.nix).
