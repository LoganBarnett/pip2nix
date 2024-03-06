{
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-20.09";
    };

    flake-utils = {
      type = "github";
      owner = "numtide";
      repo = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils }:
(let
    in {
      overlays = (final: prev: {
        pip2nix = (prev.lib.debug.traceSeq (import ./release.nix {
          pkgs = prev.pkgs;
          nixpkgs = prev.nixpkgs;
        } ).pip2nix).python39Packages.pip2nix.override (attrs: let
          # TODO: Make a helper or put it closer to the source.
          src-filter = path: type:
            let
              ext = prev.lib.last (prev.lib.splitString "." path);
              parts = prev.lib.last (prev.lib.splitString "/" path);
            in
              !prev.lib.elem (prev.lib.basename path) [".git" "__pycache__" ".eggs" "_bootstrap_env"] &&
              !prev.lib.elem ext ["egg-info" "pyc"] &&
              !prev.lib.startsWith "result" (prev.lib.basename path);
          in rec {
          src = builtins.filterSource src-filter ./.;
          buildInputs = [
            prev.pip
            prev.pkgs.nix
          ] ++ attrs.buildInputs;
          pythonWithSetuptools = prev.python.withPackages(ps: [
            ps.setuptools
          ]);
          propagatedBuildInputs = [
            pythonWithSetuptools
          ] ++ attrs.propagatedBuildInputs;
          preBuild = ''
        export NIX_PATH=nixpkgs=${prev.pkgs.path}
        export SSL_CERT_FILE=${prev.pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      '';
          postInstall = ''
        for f in $out/bin/*
        do
          wrapProgram $f \
            --set PIP2NIX_PYTHON_EXECUTABLE ${pythonWithSetuptools}/bin/python
        done
      '';
        });
      });
    }) //
(flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      packages = import ./release.nix {
        inherit pkgs;
      };
      defaultPackage = packages.pip2nix.python39;
    in {
      inherit packages defaultPackage;
    }));
}
