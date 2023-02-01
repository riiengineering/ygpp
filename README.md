# ygpp
Yoshi's Generic Preprocessor

## Installation

To install ygpp(1) the only requirement is a POSIX compatible sh(1) and awk(1)
implementation.

## Usage

`[DEF1=value [DEF2=something] ...] ygpp inputfile [concat...]`

## Example input file

`hello.ygpp`:
```
#ifndef WORLD
#define WORLD world
#endif
Hello %{WORLD}!
```

This file when processed using `ygpp hello.ygpp` prints:
> Hello world!

When processed using `WORLD=Yoshi ygpp hello.ygpp` prints:
> Hello Yoshi!


## Syntax

### Variable Expansions

Variables can be expanded in the input file by using the `%{var}` syntax.

### Comments

#### `#dnl [comment]`

add a comment


### Conditionals

#### `#define [DEF] [VALUE]`

define the `DEF` definition as `VALUE`.

#### `#undef [DEF]`

undefine the `DEF` definition.

#### `#if [SHELL COMMAND]` ... [`#else` ...] `#endif`

only include the lines between the `#if` and `#endif` lines if the
`SHELL COMMAND` has an exit status of `0`.

All the `#defines` will be available as variables in the shell command.

#### `#ifbool [!]VARIABLE` ... [`#else` ...] `#endif`

only include the lines between the `#ifbool` and `#endif` lines if the
environment `VARIABLE` is "truthy", i.e. `TRUE`/`True`/`true` or a non-zero
number.  
All other values are considered "falsey".

The result can be inverted by prepending exclamation points (!) to the variable
name.

#### `#ifdef VARIABLE` ... [`#else` ...] `#endif`

only include the lines between `#ifdef` and `#endif` if `VARIABLE` was defined
in the process' environment.

#### `#ifndef VARIABLE` ... [`#else` ...] `#endif`

like `#ifdef` but negated, i.e. the lines inside this block are printed if
`VARIABLE` is *not* defined in the process' environment.


### Blocks

#### `#defblock [BLOCK NAME]` ... `#endblock`

define a reusable block.


#### `#useblock [BLOCK NAME]`

insert the contents of `BLOCK NAME` as if they were included in the input file
instead of the `#useblock` line.


### Other

#### `#include [otherfile]`

include the contents of `otherfile` as if its contents were included in the
input file in place of the `#include` line.
