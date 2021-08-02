{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, clap ? import ./../lib/default.nix { inherit lib; }, ... }:
let

  check = pkgs.callPackage ./check.nix { inherit clap; };
  opts = pkgs.callPackage ./opts.nix { };

  checkNixfmt = builtins.trace pkgs.system
    (if pkgs.system == "aarch64-darwin" then
      [ ] # TODO: wait for nixfmt on darwin m1.
    else
      [
        (pkgs.stdenvNoCC.mkDerivation {
          name = "check-nixfmt";
          phases = [ "nixfmt" ];
          nixfmt = ''
            find ${
              ./..
            } -type f -iname "*.nix" -print0 | xargs -0 ${pkgs.nixfmt}/bin/nixfmt -c && touch $out
          '';
        })
      ]);

  testFiles = lib.filter (lib.hasSuffix "-test.nix")
    (lib.filesystem.listFilesRecursive ./.);

  checkFiles =
    map (f: check (import f { inherit lib pkgs clap opts; })) testFiles;

  checks = checkNixfmt ++ checkFiles;

in checks
