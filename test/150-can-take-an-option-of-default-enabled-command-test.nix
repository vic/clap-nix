{ opts, ... }:

{
  name = "can take an option of default-enabled command";
  argv = [ "--foo" 42 "--moo" 23 "--baz" 99 ];
  at = (_: _.opts);
  lsc = {
    long.foo = opts.int;
    command.bar.enabled = true;
    command.bar.long.baz = opts.int;

    command.bat.long.man = opts.int;
  };
  expected = {
    rest = [ "--moo" 23 ];
    seen = {
      long.foo = 42;
      command.bar.long.baz = 99;
      command.bar.enabled = true;

      command.bat.enabled = false;
      command.bat.long = { };
    };
  };
}
