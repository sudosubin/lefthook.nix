{ pkgs }:

{
  run = pkgs.callPackage ./run.nix { inherit pkgs; };
}
