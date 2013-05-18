# Ruby2600

A (work-in-progress) Atari 2600 emulator 100% written in Ruby

## Rationale

Emulator development and the "Ruby way" of writing code were two areas that I wanted to get more experience, and this project allowed me to do both. Speed is **not** a concern (Stella does that very well), but I wanted to end up with n emulator with high test coverage and easy to understand/modify code.

So far, it is going well: the 650x CPU emulation covers about 65% of the instruction set and (cloc)[http://cloc.sourceforge.net/]s only 260 lines of code, and every instruction is tested for expected effects (and a few unexpected ones).

## Installation

Once this gem is published), you can just install it:

    $ gem install ruby2600

For now, you'll have to install it from the cloned source

    FIXME add command

## Usage

The command line is pretty minimal now:

    $ ruby2600 enduro.bin

## License

Copyright (c) 2013 Carlos Duarte do Nascimento (Chester) <cd@pobox.com>

See the file license.txt for copying permission.
