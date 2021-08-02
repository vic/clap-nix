{ opts, ... }:

{
  name = "opts returns a merged config using evalModules";
  argv = [ "--foo" 42 "bar" "--moo" 23 "--baz" 99 ];
  at = (_: _.opts);
  lsc = {
    long.foo = opts.int;
    command.bar.long.baz = opts.int;
    command.bat.long.man = opts.int;
  };
  expected = {
    rest = [ "--moo" 23 ];
    seen = {
      long.foo = 42;
      command.bar.enabled = true;
      command.bar.long.baz = 99;

      command.bat.enabled = false;
      command.bat.long = { };
    };
  };
}
