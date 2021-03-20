{
  description = "A small library providing macros to add source location to monadic error handling.";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;

  inputs.lean.url = "github:leanprover/lean4";
  inputs.flake-utils.url = github:numtide/flake-utils;

  inputs.assrt-command.url = github:pnwamk/lean4-assert-command;
  inputs.assrt-command.inputs.lean.follows = "lean";

  outputs = { self, lean, flake-utils, assrt-command, nixpkgs}: flake-utils.lib.eachDefaultSystem (system:
    let
      leanPkgs = lean.packages.${system};
      pkg = leanPkgs.buildLeanPackage {
        name = "LeanErrorLocation";  # must match the name of the top-level .lean file
        src = ./.;
        deps = [assrt-command.packages.${system}];
      };
    in {
      packages = pkg // {
        inherit (leanPkgs) lean;
      };

      defaultPackage = pkg.modRoot;
    });
}

