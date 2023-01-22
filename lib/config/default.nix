{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;
  cfg = config;

  configFile = pkgs.runCommand "lefthook.yml"
    {
      buildInputs = [ pkgs.jq ];
      passAsFile = [ "rawJSON" ];
      rawJSON = builtins.toJSON cfg.config;
    } ''
    {
      echo "# This file is generated by lefthook.nix in your project."
      echo "# Manual changes might be lost."
      jq . <"$rawJSONPath"
    } >$out
  '';

in
{
  options = {
    package = mkOption {
      type = types.package;
      description = lib.mdDoc ''
        `lefthook` package to use.
      '';
      default = pkgs.lefthook;
    };

    config = mkOption {
      type = types.attrs;
      description = lib.mdDoc ''
        lefthook configuration to use.
      '';
    };

    rootSrc = mkOption {
      type = types.path;
      description = lib.mdDoc ''
        The root path for lefthook.
      '';
    };

    run = mkOption {
      type = types.package;
      readOnly = true;
    };

    installationScript = mkOption {
      type = types.str;
      readOnly = true;
    };
  };

  config = {
    run = pkgs.runCommand "lefthook-run" { buildInputs = with pkgs; [ git ]; } ''
      set +e
      export HOME="$PWD"

      cp -R ${cfg.rootSrc} ./src
      rm -rf ./src/.git
      chmod -R +w ./src
      ln -fs ${configFile} ./src/lefthook.yml

      cd ./src
      git init
      git add .
      ${cfg.package}/bin/lefthook run pre-commit

      exitcode=$?
      touch $out  # TODO
      [ $? -eq 0 ] && exit $exitcode
    '';

    installationScript = ''
      export PATH=${cfg.package}/bin:$PATH
      function _log() { echo 1>&2 "$*"; }

      if ! command -v git >/dev/null; then
        _log "WARNING: lefthook.nix: git command not found, skipping installation."
      elif [ ! -d .git ]; then
        _log "WARNING: lefthook.nix: .git directory does not exist, skipping installation."
      else
        # These update procedures compare before they write, to avoid
        # filesystem churn. This improves performance with watch tools like lorri
        # and prevents installation loops by via lorri.

        if readlink lefthook.yml >/dev/null \
            && [[ $(readlink lefthook.yml) == ${configFile} ]]; then
          _log "lefthook.nix: lefthook configuration up to date"
        else
          _log "lefthook.nix: updating $PWD lefthook configuration"

          if [ -L lefthook.yml ]; then
            unlink lefthook.yml
          fi

          if [ -f lefthook.yml ]; then
            _log "WARNING: lefthook.nix: lefthook.yml already exists. Please remove lefthook.yml and add lefthook.yml to .gitignore."
          else
            ln -s ${configFile} lefthook.yml

            # Remove previously installed git hooks
            lefthook uninstall

            # Add lefthook git hooks
            lefthook install
          fi
        fi
      fi

      unset -f _log
    '';
  };
}