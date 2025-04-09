{ pkgs, lib }:
{
  config ? { },
  src,
}:

let
  eval = lib.evalModules {
    modules = [
      (import ./config)
      {
        config = {
          inherit config;
          rootSrc = src;
          _module.args.pkgs = pkgs;
        };
      }
    ];
  };

in
eval.config.run
// {
  shellHook = eval.config.installationScript;
}
