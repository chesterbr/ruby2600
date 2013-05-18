# Ruby2600

A (work-in-progress) Atari 2600 emulator, 100% written in Ruby.

## Motivation

Emulator development and the "Ruby way" of writing code were two areas that I wanted to explore, and this project allowed me to do both.

The main focus is to avoid "writing C in Ruby". Instead, the code is geared towards clarity and compatibility, by means of means of strict, RSpec-based TDD.

This will (hopefully) result in specs that can  used in other contexts (e.g., testing other 650x CPU emulators, or using the current one in other projects).

Speed and sound are lowest-priority goals ([Stella](http://stella.sourceforge.net/) or [z26](http://www.whimsey.com/z26/) can suit most needs in those respects right now). Once (and if) it reaches reasonable compatibility with general games we can look at those aspects.

## Current status

- 650x CPU emulation covers about 65% of the instruction set, [cloc](http://cloc.sourceforge.net/)-ing just about 260 lines of code.
- TIA emulation covers basic VSYNC/VBLANK, playfield registers and CPU sync (including WSYNC), being able to generate an entire scanline or even a full frame (in Atari colors)
- Every single aspect of the emulated code is spec-ed.
- Rudimentary [Gosu](http://www.libgosu.org/)-based command-line interface allows running a [Hello World ROM](http://pastebin.com/abBRfUjd), which is also included on a functional test.

## Installation

Once this gem is published), you'll be able to just install it:

    $ gem install ruby2600

For now, clone the project and `bundle install` the dependencies.

## Usage

You can use then `bundle exec rspec` or `bundle exec guard` to run the tests, or go wild on `irb`/`pry` (disassembler/debug tools will come soon).

Command line is pretty minimal now, and most likely only runs the Hello World cart (with funky colors). You can run straight from a clone/fork with:

    $ bundle exec ruby -Ilib bin/ruby2600 spec/fixtures/files/hello.bin

## License

If you can see this repository, it means I gave you a sneak preview. Play with it as you wish, but please don't share until it is released - ping me if you have any need otherwise!

Once released (planned for [RubyConf BR 2013](http://cfp.rubyconf.com.br/)), this software will be distributed under the terms of the [MIT License](http://opensource.org/licenses/MIT). If you have access right now, it me

Copyright (c) 2013 Carlos Duarte do Nascimento (Chester) <cd@pobox.com>

See the file LICENSE.txt for copying permission.
