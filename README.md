# ygpp

Yoshi's Generic Preprocessor (ygpp) is an easy to use generic file preprocessor
which is inspired by the well-known C preprocessor (`cpp(1)`).

ygpp is implemented in pure POSIX [`awk(1)`](http://www.opengroup.org/onlinepubs/9699919799/utilities/awk.html).

## Installation

**Requirements:**  
To install ygpp the only requirement is a POSIX compatible `awk(1)` and
`sh(1)` implementation to be available.  

To install ygpp from source:
```sh
make AWK=awk prefix=/usr/local install
````

If you really want to, you can also install the latest version directly from the
web:
```sh
curl -L -o ~/.local/bin/ygpp https://github.com/riiengineering/ygpp/raw/main/ygpp
```
You need to adjust the shebang line manually if you don't want to use
`/usr/bin/awk`.

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

#### `#switch VARIABLE` [`#case ...` ...]... [`#default` ...] `#endswitch`

switch based on the current contents of `VARIABLE`.
the `#case`s are _not_ fall-through like they are in C-like languages.

The `#default` branch will be used if none of the `#case`s matched.
Thus `#default` must be last.

The behaviour is unspecified when a `#case` with the same value occurs more than once.


### Loops

#### `#foreach VARIABLE ITEMS...` ... `#endforeach`

re-evaluate the lines between `#foreach` and `#endforeach` once for every `ITEM`
(a space-separated list of items, including `%`-expansions) with the `VARIABLE`
being set to each of the `ITEMS` once.

`#foreach` cannot be nested.

The `VARIABLE` is scoped to the `#foreach` block. The value of `VARIABLE` is restored at the end of the foreach loop.

### Blocks

#### `#defblock [BLOCK NAME]` ... `#endblock`

define a reusable block.


#### `#useblock [BLOCK NAME]`

insert the contents of `BLOCK NAME` as if they were included in the input file
instead of the `#useblock` line.


### Other

#### `#error [message]`

print an error message to `stderr` and terminate ygpp with exit status 1.

#### `#warning [message]`

print a warning message to `stderr`, but continue processing the input file.

#### `#include [otherfile]`

include the contents of `otherfile` as if its contents were included in the
input file in place of the `#include` line.

-----
[![riiengineered.](https://www.riiengineering.ch/riiengineered-400.png)](//www.riiengineering.ch)
