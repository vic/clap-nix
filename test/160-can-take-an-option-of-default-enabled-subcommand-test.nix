{ opts, ... }:

{
  name = "can take an option of default-enabled subcommand";
  argv = [ "--foo" 42 "bar" "--moo" 23 "--man" 99 ];
  at = (_: _.opts);
  slac = {
    long.foo = opts.int;
    command.bar.long.baz = opts.zero;

    command.bar.command.bat.enabled = true;
    command.bar.command.bat.long.man = opts.int;
  };
  expected = {
    rest = [ "--moo" 23 ];
    seen = {
      long.foo = 42;
      command.bar.enabled = true;
      command.bar.long.baz = 0;

      command.bar.command.bat.enabled = true;
      command.bar.command.bat.long.man = 99;
    };
  };
}
