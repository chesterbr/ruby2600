# ruby2600

An experimental Atari 2600 emulator, 100% written in Ruby.

![ruby2600](http://i.imgur.com/Zjgibpr.png "ruby2600")

## Current status

Most 2K and 4K games show at least their title screens. Some (e.g., *Pitfall!™*, *River Raid™*) are quite playable (at what feels like ~1/30 of the speed of a real Atari on my "late 2012"" Mac Mini).

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
- *3*/*4* - Color switch (3 = Color; 4 = black and white)
- *5*/*6* - Player 0 difficulty switch (5 = Beginner, 6 = Advanced)
- *7*/*8* - Player 1 difficulty switch (7 = Beginner, 8 = Advanced)
- *W/A/S/D* - "Sticky" Player 0 joystick (to stop moving, press the non-sticky arrow)

## Known issues

- Objects rendered close to the left side sometimes render in wrong positon (see diagonal.bin test);
- Some games are extending to long frames (River Raid, Boxing, Space Invaders);
- Some games display an artifact at the left side where there should be nothing (Freeway, Boxing);
- Some sprites seem off-by-one on specific games (see tip of hidden subs on Seaquest);

Technical debt:

- UI code needs some love (just quickly slapped a [Gosu](http://www.libgosu.org/) script on /bin to make it playable; would seriously consider a JRuby-friendly version);
- CPU code could be refactored to get rid of the "instruction/operation" difference;
- Might want to split MovableObject into the Graphic (the real superclass) and Counter (an utility that should be composed).

## FAQ

#### Why?

I had two (somewhat) unrelated goals for this year:

- Learning more about the 2600 (to write a game in the future);
- Getting more proficient with Ruby and RSpec.

The emulator is the way I found to tackle to do both at once.

#### Emulator in Ruby? Is that possible?

Yes, it is, and ruby2600 shows that.

#### And how good it is?

Not really good if your goal is playing games. Keep in mind that:

- It is **slow** (~1/10 of a real Atari on my computer).
- It has **no sound**.
- It has **a few glitches** (see ).

It is good, however, if you want to learn more about the 2600, as the lack of concerns with speed makes the code more accessible than the average emulator.

#### Will you make it faster/add sound?

Once (and if) ruby2600 reaches reasonable compatibility with general games, these aspects can be looked after. For now, I'm focused on fixing the glitches, making the code clear, and improve the specs as much as possible.

If you want a full-speed emulator with sound and compatible with every single game under the sun, I wholehartedly recommend [Stella](http://stella.sourceforge.net/) - which has been an invaluable source of inspiration, debug help and implementation reference. It's what I use to play (other than my real Atari).

#### What is the current status?

It boots almost every 2K/4K cart I've tried, and you can play quite a few of them (reeeeaaaalyyy slooowwwwlyyyy). Tech details:

- Full 650x instruction set emulation, [cloc](http://cloc.sourceforge.net/)-ing less than 380 lines of code. (hardware interrupts not emulated, as the 2600 does not have them);
- RIOT fully implemented;
- TIA registers are all emulated, with the exception of audio (AU*) and hardware test (RSYNC);
- Every single aspect of the emulated code is spec-ed, except for some TIA parts I am still figuring out.

## Changelog

##### 0.1.0
- First release with full (sans sound) TIA emulation

## License

If you can see this repository, it means I gave you a sneak preview. Play with it as you wish, but please don't share until it is released - ping me if you have any need otherwise!

Once released (planned for [RubyConf BR 2013](http://cfp.rubyconf.com.br/)), this software will be distributed under the terms of the [MIT License](http://opensource.org/licenses/MIT). If you have access right now, it me

Copyright (c) 2013 Carlos Duarte do Nascimento (Chester) <cd@pobox.com>

Atari™ word trademarks owned by Atari Interactive, Inc., which this software and its authors do not claim to hold or represent in any way. Any other software mentioned is property of his/her respective owners.

See the file LICENSE.txt for copying permission.
