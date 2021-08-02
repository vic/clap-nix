# clap.nix - Command Line Argument Processing in Nix.

This library provides a `clap` Nix function for parsing command line arguments into a Nix attribute set.

[![Test](https://github.com/vic/clap-nix/actions/workflows/test.yml/badge.svg)](https://github.com/vic/clap-nix/actions/workflows/test.yml)

#### Features

- The [implementation](lib/default.nix) and [tests](test) are pure Nix.

- Familiar `--long` and `-s`hort option styles.

- Boolean long options can be negated with `--no-` surprises.

- Short options can be collapsed. `-abc` equals `-a -b -c`.

- Option values can be any Nix data type, not only strings.

- Nested trees of commands as popularized by tools like `git`.

- A path of subcommands can be enabled by default.
  (eg, you can make `foo help` be executed when `foo` receives no more arguments)

- Options are specified by virtue of Nix `lib.mkOption` and `lib.types`. 
  Meaning your options can provide defaults, value 
  coercions, aggregation or be compositions of different types.

- Leverages the power of `lib.evalModules` so you can define
  option aliases (eg, `-h` and `--help` having the same value)
  or define your own config by providing custom Nix modules and
  using `lib.mkIf` and friends.

- Distributed as a flake or legacy library.

- Made with <3 by [oeiuwq](https://twitter.com/oeiuwq).


### The `{long ? {}, short ? {}, command ? {}, ...}` tree.

An `lsc` tree describes the structure of the command line interface
that will be parsed using the `clap` Nix function.

``` nix
{
  # an attribute set of one letter options
  short = {
    f = lib.mkOption {
      description = "file";
      type = lib.types.path;
    };
  };

  # an attribute set of long options
  long = {
    help = lib.mkEnableOption "help";
  };
  
  # and attribute set of sub-commands and their `lsc` tree.
  command = {
    show = {
      long = {
        pretty = lib.mkEnableOption "pretty print";
      };
      # ... other short, or command sets.
    };
  };
}
```


### Calling the `clap` function.

Once you have your `lsc` tree definition, you are ready to invoke `clap` with some
command line arguments.

``` nix
{ clap, ... }:
let
  lsc = # the attribute set from the snippet above.

  ####
  # The important thing on this snipped is how to invoke the `clap` function:
  # 
  # The firsr argument is the `lsc` tree structure that defines the CLI design.
  # Second argument is a list of Nix values (not just strings) representing 
  # the user entered command line arguments.
  cli = clap lsc [ "--help" ];
in
  # More on `clap` return value in the following section.
  if cli.opts.long.help then
    # somehow help the user.
  else
    # actually do the thing.
```


### The return value `clap`.

The following is an annotated attribute set with the values returned to you by `clap`:

``` nix
{
  # A list of all arguments not processed by `clap`
  # Unknown options and unused values will be aggregated in this list.
  # Also, if `clap` finds the string `--` in the command line arguments,
  # it will stop further processing, so `--` and it's following arguments
  # will be in `rest` untouched.
  rest = [ ];
  
  
  # Typically you'd want to inspect the `opts` attribute in order to
  # know what options the user assigned values to. 
  # Notice that it basically follows the same structure a `lsc` has. 
  #
  # Note: Accessing `opts` will make sure that all options correspond to
  # their defined type, by virtue of using `lib.evalModules` -more on this later-,
  # and of course Nix will throw an error if some option has incorrect value type.
  opts = {
    # here you'll find `long` and `short` options assigned to their values.
    long = { help = false; };             # from `--no-help`
    short = { f = /home/vic/some-file; }; # from `-f /home/vic/some-file`
    
    # commands also map to their resolved values.
    command = {
      show = {
        enabled = true;  # meaning the user specified the `show` command.
        long = {
          pretty = true; # from `show --pretty` 
        };
      };
    };

  }; # end opts
  
  
  ##-# That's it. The attributes bellow are lower level representations of the
  # `opts` set. But could be useful anyways to you:
  
  optsSet = {}; # Another lsc-like set. *BUT* this one is not type-checked at all.

  optsMod = {}; # A Nix Module that contains all the options declarations and definitions.
                #
                # This one is useful if you want to mix with your own modules using `lib.evalModules`
                # for example, for creating option aliases or merging with other conditions.
                #
                # Actually `opts = (lib.evalModules { modules = [ optsMod ]; }).config`.
                
  optsAcc = []; # A list of attribute sets that enable options and subcommands as they are seen.
                # This is the lowest level output, optsSet and optsMod are a by-product of it
                # and it is used directly mostly in tests bellow number 100 to assert the order
                # in which options are read from the command line.
  
}
```


### Examples

##### Enabling a default subcommand

  Enabling a default command means that the user does not have to explicitly name the subcommand yet they
  can specify the subcommand's options directly. [see test](test/150-can-take-an-option-of-default-enabled-command-test.nix)

  To enable a default command you can set it's `command.foo.enabled` attribute to either a `true` boolean
  or an option with default value of `true`.
  
 ``` nix
{lib, ...}:
let 
  # an option that takes integers, not relevant to this example;
  intOption = mkOption { type = lib.types.int; };
in
{
  short.a = intOption
  
  # auto-enable this command by default, so that the user can directly use `-b` without naming `foo`
  command.foo.enabled = true;
  command.foo.short.b = intOption;

  # bar is not auto-enabled, user must explicitly the name `bar` command before setting `-c`.
  command.bar.short.c = intOption;
  
  # since foo is enabled, and its baz subcommand is also enabled, the user could simply provide `-d` directly.
  command.foo.command.baz.enabled = true;
  command.foo.command.baz.short.d = intOption;
} 
 ```

 
##### Other examples as tests.

Some other examples can be found in the [test](test/) directory.

### Developing

This repo checks for `nixfmt` on all `.nix` files.
Tests can be run using `nix flake check -L --show-trace`. 
Adding more test by adding a 10th step consecutive `-test.nix` file inside the `test/` directory.


### Wait, but why?

I know... Nix is a *configuration language* not a _general purpose_ one. Who needs to parse command line arguments via pure-nix, right? That very person happens to be [vic](https://twitter.com/oeiuwq), like many other people I've been trying to learn Nix and configure [my system](https://github.com/vic/vix) [with it](https://github.com/vic/mk-darwin-system).

Also I'm planning to release a nix-related tool soon and *really* wanted to get away from `bash` this time. So I'm just trying to program as much as I can in Nix. Yet I'm liking doing Nix a lot more than writing shell scripts with `sed,grep,read,tr,awk,bash`fulness.

### Contributing

Yes, please. Pull-requests are more than welcome!
