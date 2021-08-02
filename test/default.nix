{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib
, clap ? import ./../lib/default.nix { inherit lib; }, ... }:
let

  check = { name, argv, lsc, expected, at ? (_: _.optsAcc) }:
    let
      sname = lib.strings.sanitizeDerivationName name;
      actual = lib.pipe argv [
        (clap lsc)
        (result: {
          inherit (result) rest;
          parsed = at result;
        })
      ];
    in if actual == expected then
      pkgs.stdenvNoCC.mkDerivation {
        name = sname;
        phases = [ "pass" ];
        pass = "touch $out";
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
      };

  opts.int = lib.mkOption { type = lib.types.int; };

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

  checks = checkNixfmt ++ [

    (check {
      name = "parse empty argv with empty lsc";
      argv = [ ];
      lsc = { };
      expected = {
        parsed = [ ];
        rest = [ ];
      };
    })

    (check {
      name = "a long option takes next argument as value";
      argv = [ "--foo" 42 ];
      lsc = { long.foo = opts.int; };
      expected = {
        rest = [ ];
        parsed = [{ long.foo = 42; }];
      };
    })

    (check {
      name =
        "a long option followed by another long option is considered a true flag";
      argv = [ "--foo" "--bar" 42 ];
      lsc = {
        long.foo = opts.int;
        long.bar = opts.int;
      };
      expected = {
        rest = [ ];
        parsed = [ { long.foo = true; } { long.bar = 42; } ];
      };
    })

    (check {
      name =
        "a long option followed by a short option is considered a true flag";
      argv = [ "--foo" "-b" 42 ];
      lsc = {
        long.foo = opts.int;
        short.b = opts.int;
      };
      expected = {
        rest = [ ];
        parsed = [ { long.foo = true; } { short.b = 42; } ];
      };
    })

    (check {
      name =
        "a long option followed by a short option is considered a true flag";
      argv = [ "--foo" "-b" 42 ];
      lsc = {
        long.foo = opts.int;
        short.b = opts.int;
      };
      expected = {
        rest = [ ];
        parsed = [ { long.foo = true; } { short.b = 42; } ];
      };
    })

    (check {
      name = "last short option in combo takes the argument value";
      argv = [ "-abc" 42 ];
      lsc = {
        short.a = opts.int;
        short.b = opts.int;
        short.c = opts.int;
      };
      expected = {
        rest = [ ];
        parsed = [ { short.a = true; } { short.b = true; } { short.c = 42; } ];
      };
    })

    (check {
      name = "short option followed by long one is considered boolean";
      argv = [ "-a" "--foo" 42 ];
      lsc = {
        short.a = opts.int;
        long.foo = opts.int;
      };
      expected = {
        rest = [ ];
        parsed = [ { short.a = true; } { long.foo = 42; } ];
      };
    })

    (check {
      name = "unknown option is just rest";
      argv = [ "-a" "--foo" 42 ];
      lsc = { short.a = opts.int; };
      expected = {
        rest = [ "--foo" 42 ];
        parsed = [{ short.a = true; }];
      };
    })

    (check {
      name = "everything after double slash is just ignored";
      argv = [ "--" "-a" "--foo" 42 ];
      lsc = { short.a = opts.int; };
      expected = {
        rest = [ "--" "-a" "--foo" 42 ];
        parsed = [ ];
      };
    })

    (check {
      name = "naming a subcommand parses options for it";
      argv = [ "--foo" 42 "bar" "--baz" 23 ];
      lsc = {
        long.foo = opts.int;
        command.bar.long.baz = opts.int;
      };
      expected = {
        rest = [ ];
        parsed = [
          { long.foo = 42; }
          { command.bar.enabled = true; }
          { command.bar.long.baz = 23; }
        ];
      };
    })

    (check {
      name = "once a subcommand is found parent options are unknown";
      argv = [ "--foo" 42 "bar" "--foo" 23 ];
      lsc = {
        long.foo = opts.int;
        command.bar.long.baz = opts.int;
      };
      expected = {
        rest = [ "--foo" 23 ];
        parsed = [ { long.foo = 42; } { command.bar.enabled = true; } ];
      };
    })

  ];

in checks
