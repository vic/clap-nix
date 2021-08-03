{ lib, pkgs, clap, ... }:
{ name, argv, slac, expected, at ? (_: _.optsAcc) }:
let
  sname = lib.strings.sanitizeDerivationName name;
  actual = lib.pipe argv [
    (clap slac)
    (result: {
      inherit (result) rest;
      seen = at result;
    })
  ];
  same = actual == expected;
in if builtins.trace "* ${name}" same then
  pkgs.stdenvNoCC.mkDerivation {
    name = sname;
    phases = [ "ok" ];
    ok = "touch $out";
  }
else
  pkgs.stdenvNoCC.mkDerivation {
    name = sname;
    phases = [ "fail" ];
    passAsFile = [ "prettyArgv" "prettyActual" "prettyExpected" ];
    prettyArgv = lib.generators.toPretty { multiline = false; } argv;
    prettyActual = lib.generators.toPretty { } actual;
    prettyExpected = lib.generators.toPretty { } expected;
    fail = ''
      echo -n "with argv: "
      cat $prettyArgvPath
      echo
      echo -e "diff -y EXPECTED ACTUAL"
      ${pkgs.diffutils}/bin/diff -u100 $prettyExpectedPath $prettyActualPath | ${pkgs.gitAndTools.delta}/bin/delta --no-gitconfig --side-by-side --keep-plus-minus-markers
      false
    '';
  }
