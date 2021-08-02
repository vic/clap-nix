{ opts, ... }:

{
  name = "naming a subcommand parses options for it";
  argv = [ "--foo" 42 "bar" "--baz" 23 ];
  lsc = {
    long.foo = opts.int;
    command.bar.long.baz = opts.int;
  };
  expected = {
    rest = [ ];
    seen = [
      { long.foo = 42; }
      { command.bar.enabled = true; }
      { command.bar.long.baz = 23; }
    ];
  };
}
