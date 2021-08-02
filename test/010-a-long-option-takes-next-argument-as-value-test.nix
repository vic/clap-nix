{ lib, opts, ... }:

{
  name = "a long option takes next argument as value";
  argv = [ "--foo" 42 ];
  lsc = { long.foo = opts.int; };
  expected = {
    rest = [ ];
    seen = [{ long.foo = 42; }];
  };
}
