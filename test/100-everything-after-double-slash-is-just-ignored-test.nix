{ opts, ... }:

{
  name = "everything after double slash is just ignored";
  argv = [ "--" "-a" "--foo" 42 ];
  slac = { short.a = opts.int; };
  expected = {
    rest = [ "--" "-a" "--foo" 42 ];
    seen = [ ];
  };
}
