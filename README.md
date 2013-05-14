# Ruby2600

A (work-in-progress) Atari 2600 emulator 100% written in Ruby

## Rationale

Emulator development and the "Ruby way" of writing code were two areas that I wanted to get more experience, and this project allowed me to do both. Speed is **not** a concern (Stella does that very well), but I wanted to end up with n emulator with high test coverage and easy to understand/modify code.

So far, it is going well: the 650x CPU emulation covers about 65% of the instruction set and (cloc)[http://cloc.sourceforge.net/]s only 260 lines of code, and every instruction is tested for expected effects (and a few unexpected ones).

## Installation

I'm inclined to make Ruby2600 a gem, unless I find some better way to distribute it. If so, you'll probably be able to install it with:

    $ gem install ruby2600

## Usage

Currently you'll have to use the console. See `spec/functional\cpu_hello_world_spec` for an example on how to load an Atari cart on an array and "run" it.

At some point I'll most likely add a script, so you will be able to go like

    $ ruby2600 enduro.bin

## License

Copyright (c) 2013 Carlos Duarte do Nascimento (Chester) <cd@pobox.com>

See the file license.txt for copying permission.
