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
    flake-utils.lib.eachDefaultSystem (system: let
      packages = import ./release.nix {
        pkgs = import nixpkgs {
          inherit system;
        };
      };
      defaultPackage = packages.pip2nix.python39;
    in {
      inherit packages defaultPackage;
    }) // {
      overlay =
        (final: prev: {
          pip2nix = import ./default.nix {
            pkgs = prev.pkgs;
            # python36Packages is no longer available.
            pythonPackages = "python39Packages";
          };
        }
        #   .pythonPackagesLocalOverrides { super = final; self = prev; }).pip2nix;
        );
    };
}

