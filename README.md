# ruby2600

An experimental Atari™ 2600 emulator, 100% written in Ruby.

[![ruby2600](http://i.imgur.com/Zjgibpr.png "ruby2600")](http://www.slideshare.net/chesterbr/ruby2600-an-atari-2600-emulator-written-in-ruby)

These [RubyConfBr 2013 slides](http://www.slideshare.net/chesterbr/ruby2600-an-atari-2600-emulator-written-in-ruby) showcase the general architecture and rationale.

## Current status

[![Build Status](https://travis-ci.com/chesterbr/ruby2600.svg?branch=master)](https://travis-ci.com/chesterbr/ruby2600)

Games **working** with no noticeable glitches include:

- *Pitfall!*
- *Space Invaders*
- *River Raid*
- *Pac-Man*
- *Tennis*
- *Donkey Kong*

You can load most 2K and 4K carts and try them out.

Speed is very low: about ~2 FPS (from the expected 60) on a 2.3Ghz computer. An [accelerated video](http://www.youtube.com/watch?v=S3qAOu41CxE) shows how the emulator would run in full speed.

Also, no sound is emulated, nor any controllers other than the console switches and player 0 joystick.

Check the [Known Issues](#known-issues) and [FAQ](#faq) below for more information.

![screenshot](http://i.imgur.com/kN9Yxsi.png "Pitfall! on ruby2600, as of Aug 4")

## Installation

Standard Ruby (MRI) will use [Gosu](http://www.libgosu.org/) to display the frames and capture user input, so you need to ensure its dependencies are installed. On OS X, this does the trick:

    brew install sdl2 libogg libvorbis

(you don't need that if you run on JRuby - which uses the built-in SWT - or if you will run headless)

    git clone git@github.com:chesterbr/ruby2600.git
    cd ruby2600
    # cp .ruby-version-for-jruby .ruby-version # Only for JRuby
    rvm install # (or rbenv install, or whatever you need to install the Ruby in .ruby-version)
    gem install bundler
    bundle

## Usage

To run on MRI:

    bundle exec ruby -Ilib bin/ruby2600 /path/of/your/romfile.bin

If you're using JRuby:

    bundle exec jruby -J-XstartOnFirstThread -Ilib bin/ruby2600-swt /path/of/your/romfile.bin

For profiling/performance testing, you'll likely prefer headless mode, e.g.:

    bundle exec ruby-prof bin/ruby2600-headless /path/of/your/romfile.bin 1

(the number in the end is the number of frames to run; an extra one will be added, since first frame of most games is kind of bogus)

Notice you can add support to other VMs by creating a run script under [`/bin`][https://github.com/chesterbr/ruby2600/tree/master/bin].

### Keys

- *↑ ← ↓ →* - Player 0 joystick
- *Space* - Player 0 fire button
- *1* - GAME SELECT switch
- *2* - GAME RESET switch
- *3/4* - Color switch (3 = Color; 4 = black and white)
- *5/6* - Player 0 difficulty switch (5 = Beginner, 6 = Advanced)
- *7/8* - Player 1 difficulty switch (7 = Beginner, 8 = Advanced)
- *W/A/S/D* - "Sticky" Player 0 joystick (to stop moving, press the non-sticky matching arrow)

## Technical details

- Full 650x CPU instruction set emulation and test, [cloc](http://cloc.sourceforge.net/)-ing less than 380 lines of code. (hardware interrupts not emulated, since the 2600 does not have those);
- RIOT fully implemented and tested;
- All bus mirrorings implemented and tested; console switches and P0 joystick bindings available for any pluggable front-end.
- TIA registers are all emulated, with the exception of audio (AU*) and hardware test (RSYNC);
- Every single aspect of the emulated code is spec-ed, except for some TIA parts I am still figuring out. CPU/RIOT are pretty final, TIA might still be refactored since it suffered a lot of crazy stabs due to the lack of documentation (see below).

## Known issues

- Objects rendered close to the left side (counter zeroing during HBLANK, I suppose) sometimes render in wrong positon (see diagonal.bin test);
- Some games display an artifact at the left side (late hblank area) where there should be nothing (Freeway, Boxing);
- Donkey Kong is rendered one pixel off its Stella position;
- Seaquest renders a full scanline with the diver (missile?) at some specific situations. This bug and the three above it might be related (some odd rendering on a specific postion);
- Enduro and Jawbreaker render their frames a few dozen scanlines after the right position (Enduro leaves some trash behind, Jawbreaker leaves a black space), cutting the lower part;
- Maybe UI should dynamically adjust to games that (intentionally) generate larger/smaller frames;
- Emulator only supports NTSC games - not sure if it's worth the hassle of supporting PAL/SECAM anyway, as most(all?) PAL games are NTSC versions, and SECAM, well… sucks.
- Should display the logo during startup (either by overriding first few calls to frame, or by running a bootstrap ROM that shows it).

### Technical debt:

- MRI startup script could be improved (just quickly slapped a [Gosu](http://www.libgosu.org/) script on /bin to make it playable;
- Add an Opal generation/running script (see [this post](http://chester.me/archives/2014/02/running-ruby2600-in-a-browser-with-opal/) on running ruby2600 on Opal)
- TIA tests don't cover a few aspects (see "Pending" specs);
- `Bus` should auto-initialize the components when receiving a string (either on initialize or on a separate method);
- *Maybe* `Player`/`Ball`/`Missile`/`Playfield` should not be separate classes, since most of their code is "configuration" for the generic `Graphic` (and its `Counter`).
- There is some overuse of "magic" in CPU tests (mostly syntatic sugar to keep them descritive). Maybe it should be more properly encapsulated (outside of the test class itself).
- RSpec 3 would improve the semantics (and even make some of the aforementioned magic unnecessary)
- Convert this list to Github issues.

## FAQ

#### Why?

I had two (somewhat) unrelated goals for this year:

- Learning more about the 2600 (to write a game in the future);
- Getting more proficient with Ruby and RSpec.

The emulator is the way I found to tackle both at once.

Also, I wanted to test how well such tools coped with emulator development. Performance aside, it was a huge success: an emulator for a very tricky and under-documented system in ~3 months, written by someone that never wrote a full emulator before.

#### How good is it?

Not really good if your goal is playing games. Keep in mind that:

- It is **slow** (~1/30 of a real Atari on my computer).
- It has **no sound**.
- It has **a few glitches**.

It is good, however, if you want to learn more about the 2600, as the lack of concerns with speed makes the code more accessible than the average emulator.

#### Will you make it faster/add sound?

Now that ruby2600 reached reasonable compatibility with general games (remaining glitches are unlikely to change the emulator structure in any aspect related to performance), it can be worked. See the slides mentioned above for some planned strategies.

If you want a full-speed emulator with sound and compatible with every single game under the sun, I wholehartedly recommend [Stella](http://stella.sourceforge.net/) - which has been an invaluable source of inspiration, debug help and implementation reference. It's what I use to play (other than my real Atari).

#### Is this logo renderable on an Atari?

Not sure, I did it one day I was too bored to write code or slides. I'd say yes (as a playfield), as long as you are flexible with the background color (or use another object to render the characters). But I liked it, so I might eventually try to make a ROM that displays it.

#### How to browse the source code?

The slides mentioned above will give you an overview of the core classes. If you understand Atari architecture well, you may start with [`Bus`](https://github.com/chesterbr/ruby2600/blob/master/lib/ruby2600/bus.rb) (which, unsurprisingly, connects all the pieces together). [`CPU`](https://github.com/chesterbr/ruby2600/blob/master/lib/ruby2600/cpu.rb) is completely independent and may also be a good starting point.

## Optimization Ideas

Here is a backlog of things that may help towards increasing performance:

- [ricbit](http://github.com/ricbit) suggested we try to cache the scanlines. Essentially, given a specific TIA (+CPU/RIOT?) state, the scanline generated will be pretty much the same, so we could skip everything if no TIA registers are changed throughout drawing. He mentioned hefty gains on [BrMSX](http://www.msxpro.com/mirror/ricardo/brmsx.htm) by doing so. We just need to ensure consistent state on internal counters (although we could add them as part of the mentioned state hash key and the final value on the cached scanline) and other detail like that.
- [Georges](https://github.com/gbenatti) made some experiments with unrolling loops, finding a 2x increase by simply doing [this](https://gist.github.com/gbenatti/6498776). It seems cache-related (increasing from 16 to 32 unrolled cycles killed the improvement), but there may be some gains around here (oddly, both MRI and JRuby had improvements working that way)
- We could easily do the color translation (currently done by the ui scripts) whenever a color register is written to, greatly reducing the number of lookups. We could also keep the more frequently used colors on a quick-access location (would not help with "rainbow" bound games, but quite a few stick to a reduced color set)
-  [Lucas Fontes](https://github.com/lxfontes) tried reusing the scanline array with no noticeable improvement, but we might try having a fixed "framebuffer" array and rewriting it constantly, to kill the instantiation payload, or even consider an alternative structure to store the bytes. UPDATE: The `FrameGenerator` class makes it easy to test those things; I did an initial attempt of reusing buffer / using [NArray](http://narray.rubyforge.org/) for each scanline, but no noticeable improvement was found (maybe MRI *is* being smart enough to use integer types where appropriate).
- Even though advanced pipelining is hard to implement on old architectures like 650x, it would be theoretically possible to parallelize the fetch/decode/execute phases (like most ARM processors do). Proper profiling is needed to assert the actual benefit of such an strategy before actually implementing it.
- [Optcarrot](https://github.com/mame/optcarrot) did awesome strides regarding performance that we could benefit from. In particular, the CPU-GPU parallelism and other optimizations from [the RubyKaigi presentation](http://www.slideshare.net/mametter/optcarrot-a-pureruby-nes-emulator).
- [JRuby+Truffle](https://eregon.me/blog/2016/11/28/optcarrot.html) is capable of running OptCarrot at 150fps, worth taking a look.

## Changelog

##### 0.1.3
- Separated frame generation from TIA emulation; added headless mode and improved FPS counting; reworked most-used methods based on [ruby-prof](https://github.com/ruby-prof/ruby-prof) information.

##### 0.1.2
- Separated MovableObject: now Player, Missile, Ball and Playfield are subclasses of Graphic (which only deals with drawing), which is composed from Counter (focused on position and movement) with no delegation. This design clarifies intentions on TIA ("reset this object's counter" = object.counter.reset) which is fundamental now.

##### 0.1.1
- BIT instruction bug fixed; Pitfall, River Raid and Space Invaders playable (except for some artifacts)

##### 0.1.0
- First release with full (sans sound) TIA emulation

## Credits and Acknowlegdements

Original code was written and is currently mantained by [Carlos "Chester" Duarte do Nascimento](https://github.com/chesterbr), with acknowledgment and special thanks for contributions from the developers alphabetically listed below:

- [André Luiz Carvalho](https://github.com/alcarvalho)
- [Maurício Szabo](https://github.com/mauricioszabo)

Development would not be possible without all the great sources of 2600 information on the web, such as:

- [Stella Programming Guide](http://atarihq.com/danb/files/stella.pdf), a 1979 manual from [Steve Wright](https://atariage.com/programmer_page.html?ProgrammerID=145&orderBy=Name&orderByValue=Descending), reconstructed by Charles Sinnett in the 90s;
- AtariAge's [2600 Programming forum](http://atariage.com/forums/forum/50-atari-2600-programming/)) and [useful links](https://atariage.com/2600/programming/index.html);
- [Stella emulator](http://stella.sourceforge.net/) source code and disassembler/debugger;
- Andrew Towers' [TIA hardware notes](http://www.atarihq.com/danb/files/TIA_HW_Notes.txt) (enlightening low-level analysis of the [TIA Schematics](http://www.atariage.com/2600/archives/schematics_tia/index.html));
- Neil Parker's [low-level decoding of 6502 instructions](http://www.llx.com/~nparker/a2/opcodes.html);
- [no$2k6](http://nocash.emubase.de/2k6.htm) emulator author Martin Korth's concise yet complete [Atari 2600 Specifications](http://nocash.emubase.de/2k6specs.htm).


## License and Copyright Information

This software is distributed under the terms of the [MIT License](http://opensource.org/licenses/MIT). All contributors agree to have their contributions redistributed under the same terms.

Copyright © 2013 Carlos Duarte do Nascimento (Chester) <cd@pobox.com>.

Contributed code © 2013 to their respective contributors (see github history and names above)

Atari™ word trademarks owned by Atari Interactive, Inc., which this software and its authors do not claim to hold or represent in any way. Any other software mentioned is also property of its respective owners, being mentioned solely for reference purposes.

See the file LICENSE.txt for copying permission.
