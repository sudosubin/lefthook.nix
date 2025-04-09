{
  description = "lefthook.nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) genAttrs platforms;
      forAllSystems = f: genAttrs platforms.unix (system: f (import nixpkgs { inherit system; }));

    in
    {
      lib = forAllSystems (pkgs: (import ./lib { inherit pkgs; }));

      checks = forAllSystems (pkgs: {
        lefthook-check = self.lib.${pkgs.system}.run {
          src = ./.;
          config = {
            pre-commit.commands = {
              nixfmt = {
                run = "${pkgs.lib.getExe pkgs.nixfmt-rfc-style} {staged_files}";
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

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
