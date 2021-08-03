{ opts, ... }:

{
  name = "optsSet returns a single set with all values";
  argv = [ "--foo" 42 "bar" "--foo" 23 "--baz" 99 ];
  at = (_: _.optsSet);
  slac = {
    long.foo = opts.int;
    command.bar.long.baz = opts.int;
  };
  expected = {
    rest = [ "--foo" 23 ];
    seen = {
      long.foo = 42;
      command.bar.enabled = true;
      command.bar.long.baz = 99;
    };
  };
}
