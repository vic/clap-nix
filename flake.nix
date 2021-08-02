{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      allSystems = flake-utils.lib.defaultSystems ++ [ "aarch64-darwin" ];
      perSystem = (system:
        let
          pkgs = import nixpkgs {
            system =
              # aarch64-darwin is here just so that vic can run this on his setup.
              # however, since nixpkgs requires haskell we fallback to x86 while
              # it's available.
              if system == "aarch64-darwin" then "x86_64-darwin" else system;
          };

          clap = (pkgs.callPackage ./. { }).clap;

          tests = pkgs.callPackage ./test { inherit clap; };

          checks = pkgs.lib.foldl (a: b: a // b) { }
            (map (t: { ${t.name} = t; }) tests);

        in { inherit clap checks; });
    in flake-utils.lib.eachSystem allSystems perSystem;
}
