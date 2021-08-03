{ opts, ... }:

{
  name = "unknown option is just rest";
  argv = [ "-a" "--foo" 42 ];
  slac = { short.a = opts.int; };
  expected = {
    rest = [ "--foo" 42 ];
    seen = [{ short.a = true; }];
  };
}
