{ opts, lib, ... }:

{
  name = "long option taking boolean ignores next arg";
  argv = [ "--foo" "a" 42 ];
  slac = { long.foo = opts.bool; };
  expected = {
    rest = [ "a" 42 ];
    seen = [{ long.foo = true; }];
  };
}
