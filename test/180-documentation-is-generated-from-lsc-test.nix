{ opts, typs, lib, ... }:

{
  skip = "WIP";
  name = "documentation is generated from slac";
  fn = cli: argv: cli.docs;
  at = (_: _.flatten { });
  slac = {
    long.foo = lib.mkEnableOption "Foo";
    short.f = lib.mkOption {
      description = "file to read";
      type = lib.types.path;
    };
    command.moo.enabled = true;
    command.moo.short.b = lib.mkOption {
      description = "Bar";
      default = "bar";
      type = lib.types.str;
    };
  };
  expected = [ ];
}
