{
  description = "Easily manage git hooks with Nix, internally using lefthook.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        lib = import ./lib { inherit pkgs; };
        pkgs = import nixpkgs { inherit system; };

      in
      {
        inherit lib;

        checks = {
          lefthook-check = lib.run {
            src = ./.;
            config = {
              pre-commit.commands = {
                nixpkgs-fmt.run = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt {staged_files}";
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
