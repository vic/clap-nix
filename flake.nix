{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-utils.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      allSystems = flake-utils.lib.defaultSystems ++ [ "aarch64-darwin" ];
      perSystem = (system:
        let
          pkgs = import nixpkgs {
            system =
              if system == "aarch64-darwin" then "x86_64-darwin" else system;
          };

          lib = nixpkgs.lib;

          tests = import ./test { inherit pkgs lib; };

          checks =
            lib.foldl (a: b: a // b) { } (map (t: { ${t.name} = t; }) tests);

        in { inherit checks; });
    in flake-utils.lib.eachSystem allSystems perSystem;
}
