{ opts, typs, lib, ... }:

{
  name = "documentation is generated from lsc";
  skip = "TODO: still working on doc generation";
  fn = cli: argv: cli.doc { };
  at = lib.id;
  slac = {
    short.b = opts.val "y";
    argv = [ (typs.val "A") ];

    command.bar.enabled = true;
    command.bar.argv = [ (typs.val "B") (typs.val "C") ];
  };
  expected = {
    rest = [ ];
    seen = ''
      JO
    '';
  };
}
