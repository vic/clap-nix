{ opts, ... }:

{
  name = "once a subcommand is found parent options are unknown";
  argv = [ "--foo" 42 "bar" "--foo" 23 ];
  slac = {
    long.foo = opts.int;
    command.bar.long.baz = opts.int;
  };
  expected = {
    rest = [ "--foo" 23 ];
    seen = [ { long.foo = 42; } { command.bar.enabled = true; } ];
  };
}
