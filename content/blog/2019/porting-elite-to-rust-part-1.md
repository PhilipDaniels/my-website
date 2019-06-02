---
title: "Porting Elite to Rust, Part 1"
date: "2019-06-02"
draft: true
tags: [rust, elite, gaming]
---

# Background

A couple of things happened.

Idly browsing Wikipedia one day I went down a rabbit hole of old video games, until I
arrived at the page for the classic
[Elite](https://en.wikipedia.org/wiki/Elite_(video_game)).
Intriguingly the article mentioned that a C version had been reverse-engineered by
Christian Pinder and was [available on Github](https://github.com/fesh0r/newkind).

At around the same time an article was posted to Reddit linking to
[this explanation](https://wiki.alopex.li/AGuideToRustGraphicsLibraries2019)
of the state of Rust graphics libraries.

Now, I am not a game programmer and my tinkerings with Rust haven't involved graphics
at all up to this time, but the excellent synopsis made me wonder whether I could
port Elite to Rust. I narrowed down the framework to use to
[ggez](https://github.com/ggez/ggez)
and
[quicksilver](https://www.ryanisaacg.com/quicksilver/).

Given all the buzz around WebAssembly and graphics on the web, I chose quicksilver.
An Elite that runs in the browser would be seriously cool!

# Preparation

I wanted to get ETNK running on my development machine so that I would have a running
program to compare to, so I forked the repo
[NewKind](https://github.com/PhilipDaniels/newkind)
and tried building it. Amazingly, for a 17 year old code-base it almost worked first time.
I only had to make a few small tweaks to the makefile and install the Allegro library
using
[these instructions](https://wiki.allegro.cc/index.php?title=Install_Allegro_from_Ubuntu_PPAs)
, note that I could not get it working with Allegro 5, but it worked first time with Allegro 4.

Unfortunately, running the newkind exe had an unfortunate side-effect: it completely mangled
my multi-monitor setup. I run 3 4k monitors in an 'X-wing' configuration, with the middle one
in landscape mode and the two outriggers in portrait mode. newkind decided it wanted to run
on the left hand monitor in landscape mode with half the screen off the display...it took me
about 15 minutes to find a way to kill it and restore my X displays to sanity. So my preferred
approach changed to downloading the pre-built Windows version from
[Christian Pinder's web site](https://www.christianpinder.com/games/)
and then running it in a Windows VM. This works very well, sound included.

![Elite running in a Windows VM](elite_main_window_on_windows.png)

The second step was to get an overview of the ETNK code base and consider the scale of the
task involved. When I was first learning Rust I made an attempt to port
[libsass](https://github.com/sass/libsass) to Rust which I abandoned, but remembering that
I drew up a set of guidelines to help me with this port

* Understand the scale of the task
* Understand what all the constructs in the source code do (e.g. how `static` and `extern`
  work in C)
* No understanding gaps. Try and understand everything to some degree - what the various
  modules do and how they fit together for instance. Try not to leave any 'I don't
  understand that, I'll deal with it later' bits hanging around.
* No porting gaps. Have an idea of how each major concept of in the source can be ported
  over. You don't want to get 80% of the way through and hit something that is a blocker.
* Have a draft design, even if only conceptual.
* Always be working - start at `main()` and work down. It may be tempting to start at
  the leaves of the file dependency tree as they will look like the easiest things to
  port, but if you don't have the bits that call them it is difficult to have confidence
  that you are doing it right.

I ran [tokei](https://github.com/XAMPPRocky/tokei) over ETNK and produced a
[spreadsheet](https://docs.google.com/spreadsheets/d/1B9n7XG6rgLsdnp25g46sEi9K-41xfGNC4vLrXuKCDBo/edit#gid=934773713)
showing the line breakdown. Then I opened up each file in an editor and wrote a synopsis
of each file. The take-away from this is that there are only 11,000 lines of C, a large
proportion of which is constant data definitions such as ship and planet data. I also
have to compliment Christian Pinder here: this is the cleanest C code base I have ever
seen.

I also tried using [cinclude2dot](https://www.flourish.org/cinclude2dot/) to generate
a [GraphViz](https://graphviz.gitlab.io/) dot graph of the `#include` relationships,
but this wasn't very useful.

After this study, I had a reasonable grasp of the whole code base:

* Some standard C code for data structure definitions
* Some 3D arithmetic
* Small amount of File IO for loading and saving config and player states
* Keyboard handling
* Main game loop
* Graphics and sound routines via the Allegro library

As I mentioned above I am not a game programmer, so the basic operation of the game loop
was a pleasant surprise to me in how simple it was. Basically there is a certain game state,
input events are handled and the game state is updated, and then the screen is redrawn.
Pretty simple really. And of course, it all runs on a single thread.

The only part that gave me some concern was the use of the Allegro graphics library so I
spent more time here drilling into what is actually happening. The drawing of simple points,
lines and pixels was not a problem, but there are also assets involved, such as a `.BMP` file
for the scanner at the bottom of the screen, `.midi` files for the music, `.wav` files for
sounds and also an Allegro asset file archive called `elite.dat`. My attempts to extract
any meaningful data from this on Linux failed miserably, luckily the Windows download version
appears to have all these assets in their extracted forms. (They are all in my
[Forked NewKind](https://github.com/PhilipDaniels/newkind)
as extracted files).

# Proof-of-concept

Given concerns about the assets, before porting in earnest I decided to do a proof-of-concept
to 'go-deep' and check that there would be no blockers. The aims of this POC, over and above
getting Quicksilver up and running, were

1. Draw the scanner. This is a Windows BMP.
2. Play an mp3.
3. Play a WAV.
4. Load and save some data to persistent storage.
5. Draw the crosshairs.
6. Move the crosshairs by responding to keypresses.
8. Icon.
9. Logging.
10. Test cargo run and cargo web deploy on Windows.

Some googling indicates that MIDI files are a problem in Linux, playback cannot be guaranteed
without installing certain libraries. They don't play in my Linux Mint workstation. So I
used a free online service to convert the Elite theme tune to MP3. I also did this for
'The Blue Danube', but there are also full orchestral versions of that available for free.
Should help with the atmosphere...

I won't bore you with the details of how I did this, suffice it to say it was remarkably
easy with Quicksilver doing the heavy lifting. I managed to get all that done in one
evening. The main complexity came with figuring out the coordinate systems. ETNK contains
a lot of hard-coded coordinates which assume a 512x512 world. However, on Linux at least,
the actual window size will be 800x600 (see gfh.x, RES_800_600 is defined). And the
origin in ETNK is at the bottom left corner, whereas in Quicksilver it is at the top-right.
This means that all Y coordinates need to be translated by subtracting them from 512.
This is a potential source of bugs due to typos while porting, and I am still considering
the best way of dealing with this. But for the PoC I just hardcoded the Y coordinate
of the scanner like this (the BMP is 512x128 pixels):

```rs
    self.bitmaps.scanner.execute(|image| {
        // If we've loaded the image, draw it
        window.draw(&image.area().with_center((256, 512 - 64)), Img(&image));
        Ok(())
    })?;
```

I was very happy to discover that the window is scalable! For free! Playing in a 512x512
window on a 4k monitor is not much fun, so I was very pleased about this. Here's a screenshot of the
desktop version POC:

![Eliter PoC desktop](eliter_poc_desktop.png)

Oh and it works in the browser too, which as as simple as doing `cargo web start`:

![Eliter PoC browser](eliter_poc_browser.png)

The canvas doesn't fit the window, but I am willing to live with that for now.
Anything that works in the web I consider a bonus, but I am not going to let it
stop me from porting the game for the desktop.

If you want to play along, this is at
[Commit 015a01c47](https://github.com/PhilipDaniels/eliter/commit/015a01c473796e2f2f2f19ba02b30b97e9db6529)
.

# Links

* [Eliter](https://github.com/PhilipDaniels/eliter), my Rust port of Elite
* [Forked NewKind](https://github.com/PhilipDaniels/newkind), my fork of Elite: The New Kind, with a copy
of the extracted Windows version and some screenshots of the original
* [My Porting Spreadsheet](https://docs.google.com/spreadsheets/d/1B9n7XG6rgLsdnp25g46sEi9K-41xfGNC4vLrXuKCDBo/edit#gid=934773713),
* [Christian Pinder's](https://www.christianpinder.com/games/)
* [Guide to Rust Graphics Libraries](https://wiki.alopex.li/AGuideToRustGraphicsLibraries2019), the
  post that got me started
* [Quicksilver Home Page](https://www.ryanisaacg.com/quicksilver/), Quicksilver, the library I used
  to write Eliter
* [Cargo-web](https://github.com/koute/cargo-web), a cargo plug-in to make building web assembly
  applications easy
* [Allegro](https://liballeg.org/index.html), the home page for the Allegro game library
* [Allegro install instructions for apt](https://wiki.allegro.cc/index.php?title=Install_Allegro_from_Ubuntu_PPAs), note
  that you need to install Allegro 4
* [Elite Home Page](http://www.elitehomepage.org/index.htm), Ian Bell's Elite home page
* [Elite 30th Anniversary](http://www.elitehomepage.org/thirty/index.htm)
* [The Space Traders Flight Training Manual](http://www.elitehomepage.org/manual.htm)
* [Are we Game Yet?](http://arewegameyet.com/), Rust status page for game dev
* [webassembly.org](https://webassembly.org/), home page for web assembly
* [tokei](https://github.com/XAMPPRocky/tokei), for counting lines in source code
* [cinclude2dot](https://www.flourish.org/cinclude2dot/), for mapping `#include` relationships
* [GraphViz](https://graphviz.gitlab.io/)
