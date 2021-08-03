{ opts, ... }: {
  name = "short option as last argument is treated as boolean";
  argv = [ "--foo" "-a" ];
  slac = {
    short.a = opts.int;
    long.foo = opts.int;
  };
  expected = {
    rest = [ ];
    seen = [ { long.foo = true; } { short.a = true; } ];
  };
}
