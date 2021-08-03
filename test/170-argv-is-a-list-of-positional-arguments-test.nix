{ opts, typs, lib, ... }:

{
  name = "argv is a list of positional arguments";
  argv = [ "--foo" "A" "-b" "y" "B" "C" "D" ];
  at = (_: _.opts);
  lsc = {
    short.b = opts.val "y";
    argv = [ (typs.val "A") ];

    command.bar.enabled = true;
    command.bar.argv = [ (typs.val "B") (typs.val "C") ];
  };
  expected = {
    rest = [ "--foo" "D" ];
    seen = {
      short.b = "y";
      argv = [ "A" ];
      command.bar.enabled = true;
      command.bar.argv = [ "B" "C" ];
    };
  };
}
