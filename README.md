# ruby2600

An experimental Atari™ 2600 emulator, 100% written in Ruby.

![ruby2600](http://i.imgur.com/Zjgibpr.png "ruby2600")

## Current status

Games **working** with no noticeable screen artifacts or glitches:

- *Pitfall!*
- *Space Invaders*
- *River Raid*
- *Pac-Man*
- *Tennis*
- *Donkey Kong*

Speed is very low: about ~2 FPS (from the expected 60) on a 2.3Ghz computer.

Also, no sound is emulated, nor any controllers other than the console switches and player 0 joystick.

Check the [Known Issues](#known-issues) and [FAQ](#faq) below for more information.

![screenshot](http://i.imgur.com/kN9Yxsi.png "Pitfall! on ruby2600, as of Aug 4")

## Installation

Once this gem is published, you'll be able to install it with:

    gem install ruby2600

For now, do this:

    git clone git@github.com:chesterbr/ruby2600.git
    cd ruby2600
    bundle install

## Usage

	bundle exec ruby -Ilib bin/ruby2600 /path/of/your/romfile.bin

(it will be `ruby2600 /path/of/your/romfile.bin` once the gem is published)

There are a couple of test files under `spec/fixtures/files` you can try, but I suggest that you obtain a 2K or 4K .BIN file (for which you have the legal right to play, say, by owning the original cart).

### Keys

- *↑ ← ↓ →* - Player 0 joystick
- *Space* - Player 0 fire button
- *1* - GAME SELECT switch
- *2* - GAME RESET switch
- *3/4* - Color switch (3 = Color; 4 = black and white)
- *5/6* - Player 0 difficulty switch (5 = Beginner, 6 = Advanced)
- *7/8* - Player 1 difficulty switch (7 = Beginner, 8 = Advanced)
- *W/A/S/D* - "Sticky" Player 0 joystick (to stop moving, press the non-sticky arrow)

## Current Status

It boots almost every 2K/4K cart I've tried, and you can play quite a few of them (reeeeaaaalyyy slooowwwwlyyyy).

Some details:

- Full 650x CPU instruction set emulation, [cloc](http://cloc.sourceforge.net/)-ing less than 380 lines of code. (hardware interrupts not emulated, since the 2600 does not have those);
- RIOT fully implemented;
- All bus mirrorings implemented; console switches and P0 joystick bindings available for any pluggable front-end.
- TIA registers are all emulated, with the exception of audio (AU*) and hardware test (RSYNC);
- Every single aspect of the emulated code is spec-ed, except for some TIA parts I am still figuring out. CPU/RIOT are pretty final, TIA might still be refactored since it suffered a lot of crazy stabs due to the lack of documentation (see below).

## Known issues

- Objects rendered close to the left side (counter zeroing during HBLANK)sometimes render in wrong positon (see diagonal.bin test and Seaquest);
- Some games display an artifact at the left side (late hblank area) where there should be nothing (Freeway, Boxing);
- Most likely HMOV is being "over-applied" - no harm done, but could hamper games trying to do special effects by changing HMxx registers while HMOV is being applied.
- P0 fire button has something wrong: it fires all the time on River Raid, never on Donkey Kong (not allowing the game to start, but fine on River Raid and Space Invaders.

Technical debt:

- UI code needs some love (just quickly slapped a [Gosu](http://www.libgosu.org/) script on /bin to make it playable; would seriously consider a JRuby-friendly version); should dynamically adjust to games that generate larger/smaller frames.
- Might want to split MovableObject into the Graphic (the real superclass) and Counter (an utility that should be composed). Consider composition for both.

## FAQ

#### Why?

I had two (somewhat) unrelated goals for this year:

- Learning more about the 2600 (to write a game in the future);
- Getting more proficient with Ruby and RSpec.

The emulator is the way I found to tackle both at once.

#### Emulator in Ruby? Is that possible?

Yes, it is, and ruby2600 shows that.

#### And how good it is?

Not really good if your goal is playing games. Keep in mind that:

- It is **slow** (~1/30 of a real Atari on my computer).
- It has **no sound**.
- It has **a few glitches**.

It is good, however, if you want to learn more about the 2600, as the lack of concerns with speed makes the code more accessible than the average emulator.

#### Will you make it faster/add sound?

Once (and if) ruby2600 reaches reasonable compatibility with general games, these aspects can be looked after. For now, I'm focused on fixing the glitches, making the code clear, and improve the specs as much as possible.

If you want a full-speed emulator with sound and compatible with every single game under the sun, I wholehartedly recommend [Stella](http://stella.sourceforge.net/) - which has been an invaluable source of inspiration, debug help and implementation reference. It's what I use to play (other than my real Atari).

## Changelog

##### 0.1.2
- Separated MovableObject: now Player, Missile, Ball and Playfield are subclasses of Graphic (which only deals with drawing), which is composed from Counter (focused on position and movement) with no delegation. This design clarifies intentions on TIA ("reset this object's counter" = object.counter.reset) which is fundamental now.

##### 0.1.1
- BIT instruction bug fixed; Pitfall, River Raid and Space Invaders playable (except for some artifacts)

##### 0.1.0
- First release with full (sans sound) TIA emulation

## License

If you can see this repository, it means I gave you a sneak preview. Play with it as you wish, but please don't share until it is released - ping me if you have any need otherwise!

Once released (planned for [RubyConf BR 2013](http://cfp.rubyconf.com.br/)), this software will be distributed under the terms of the [MIT License](http://opensource.org/licenses/MIT). If you have access right now, it me

Copyright (c) 2013 Carlos Duarte do Nascimento (Chester) <cd@pobox.com>

Atari™ word trademarks owned by Atari Interactive, Inc., which this software and its authors do not claim to hold or represent in any way. Any other software mentioned is also property of its respective owners, being mentioned solely for reference purposes.

See the file LICENSE.txt for copying permission.
