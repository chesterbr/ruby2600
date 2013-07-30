# Ruby2600

A (work-in-progress) Atari 2600 emulator, 100% written in Ruby.

## Motivation

Emulator development and the "Ruby way" of writing code were two areas that I wanted to explore, and this project allowed me to do both.

The main focus is to avoid "writing C in Ruby". Instead, the code is geared towards clarity and compatibility, by means of means of strict, RSpec-based TDD.

This will (hopefully) result in specs that can  used in other contexts (e.g., testing other 650x CPU emulators, or using the current one in other projects).

Speed and sound are lowest-priority goals ([Stella](http://stella.sourceforge.net/) or [z26](http://www.whimsey.com/z26/) can suit most needs in those respects right now). Once (and if) it reaches reasonable compatibility with general games we can look at those aspects.

## Current status

Pitfall is almost playable! (at ~1/10 speed, no button, collision detection not working 100% - e.g., no log-Harry collision detected).

(need to update screenshots, maybe keep as history)

![alt text](http://i.imgur.com/9t8D7EV.jpg "Pitfall! on Stella x Ruby2600")

A more recent comparsion (after a spike rethinking the CPU-TIA sync): background priority not yet implemented, but HMOVE is good and positioning got *way* better:

![alt text](http://i.imgur.com/vqOznWI.png "Frogger on Stella x Ruby2600")

The blurry visual is due to Gosu bitmap stetch - easy to fix, but it reminds me so much of how TVs got Atari RF that I decided to keep it that way for now.

Console switches are mapped inspired on the [Stella Keys Layout](http://stella.sourceforge.net/docs/#Keyboard), but using (laptop-friendly) Mac keys instead of function keys. Right now select (1) and Reset (2) need to be held for about a second, so they can be picked up by the slow frame generator, the others are picked up naturally.


### Details

- Full 650x instruction set emulation, [cloc](http://cloc.sourceforge.net/)-ing around 350 lines of code. (hardware interrupts not emulated, as the 2600 does not have them)
- TIA emulation covers basic VSYNC/VBLANK, playfield registers and CPU sync (including WSYNC), being able to generate an entire scanline or even a full frame (in Atari colors)
- RIOT RAM and timers implemented
- Every single aspect of the emulated code is spec-ed.
- Rudimentary [Gosu](http://www.libgosu.org/)-based command-line interface allows playfield-booting some games.

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

Atari word mark and logo are trademarks owned by Atari Interactive, Inc.

See the file LICENSE.txt for copying permission.
