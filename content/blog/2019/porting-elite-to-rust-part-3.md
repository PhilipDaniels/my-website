---
title: "Porting Elite to Rust, Part 3"
date: "2019-06-16"
draft: true
tags: [rust, elite, gaming, quicksilver, webasm]
---

# The frame timer

Before we can animate the ship, we need some way of controlling the overall speed of the game.
In **Elite: The New Kind** this is done using an integer variable called `frame_count` and some
calls to Allegro. From a cursory reading there doesn't appear to be any real concept of `frames
per second`, merely a number that is adjusted until the game runs at a reasonable speed. This number
is also configurable via the `speed_cap` setting in the config file..

Quicksilver runs the game loop for you, and you
[just tell it your desired frame rate](https://docs.rs/quicksilver/0.3.14/quicksilver/tutorials/_04_lifecycle/index.html)
which you do here

```rs
let settings = Settings {
    icon_path: Some("gfx/newkind.ico"),
    // 60 times per second is actually the default rate.
    update_rate: 1000.0 / 60.0,
    .. Settings::default()
};

run::<GameState>("Eliter",
    Vector::new(graphics::SCREEN_WIDTH, graphics::SCREEN_HEIGHT),
    settings);
```

Interestingly, the rate for the `update` callback can be controlled separately from the rate for
the `draw` callback.

# Separating out update from drawing

ETNK often combines the concepts of updating the game state with drawing to the screen in a single
function. One of the major tasks in porting it to Quicksilver is to separate out the 'update state'
from the 'draw current state' logic, with the update needing to happen before drawing. In practice,
this seems to be fairly easy to do, just porting over the relevant bits from each ETNK C function
into the `GameState.update` or `GameState.draw` call stacks.

Getting the ship to animate was easy, involving a port of `update_universe` and its sub-routines.
I was pleasantly rewarded with a spinning ship (though I had to drop the rate down to make it
comparable to ETNK):


This is tag `p3`, commit [f0b09085](https://github.com/PhilipDaniels/eliter/commit/f0b0908509c8365322af3ad380b11fb361b0e035)

There is a slight problem, my ship exhibits some drawing artifacts where faces pop into and out of
existence. Not sure what is causing that yet, it's probably due to the Z-order sorting which I
couldn't be bothered to port properly and just wrote this instead:

```rs
// TODO: This might be the wrong way round.
polygons.sort_by_key(|p| -p.z);
```

If I change the `-z` to `z` then *different* polygons flash into and out of existence.
Still, it looks basically right, I'm going to put off solving that for later. I want to see
all the ships first!

# WASM no longer works

Unfortunately the code at the `p3` tag has a problem, which I only discovered later: it no
longer works in the browser. The culprit is this piece of code in `main.rs` which is designed
to initialize the random number seed:

```rs
let start = SystemTime::now();
let since_the_epoch = start.duration_since(UNIX_EPOCH).expect("Time went backwards");
let seed = since_the_epoch.as_secs() as i32;
random::set_seed(seed);
```

It panics on `SystemTime::now`, which is a
[known problem/design issue?](https://github.com/rust-lang/rust/issues/48564)
though unfortunately that issue is closed with no suggested workaround.

Since the point of this code is only to initialize ETNK's custom random number generator
with another semi-random value I just pulled in the
[rand](https://crates.io/crates/rand)
crate and changed the code to

```rs
let seed = rand::random();
random::set_seed(seed);
```

Things now work in the browser again. Lesson learnt: test often.

If you do pull this code and try running it in the browser with `cargo web start` you will
probably find that the animation is jerky. It turns out this is just debug mode for the web
and if you do a release mode build with `cargo web start --release` the animation is as
smooth as the desktop. The compilation speed will make you want to buy a new computer though!

# Intro2 solves the flashing

Once I had the intro2 screen basically working I figured out the problem with the
polygons flashing into and out of existence - this only happened on ships with lines
as well as faces. Adding another `window.flush()` to `gfx_draw_colour_line` eliminated
the problem.

# Add stars and music

Next up I ported the star fields, from `stars.c`. The code that moves the stars was
fairly easy to port, but actually drawing them threw up another conundrum. In Allegro,
individual pixels are
plotted, but Quicksilver has no concept of drawing just a pixel, so for now I am
just drawing very small filled circles. This gives a nice star-like effect, but is rather
inefficient because Quicksilver converts the circles to many triangles before sending
them to the GPU.

Music was a bigger problem. There are two music assets, the 'Elite Theme' for the first
intro screen, and 'The Blue Danube' for the second intro screen. Starting them playing
is not a problem but there is no way to stop them! You can't even set their volume to
0 once they start playing. Looking at the Quicksilver
[sound module](https://github.com/ryanisaacg/quicksilver/blob/master/src/sound.rs)
and comparing it to the
[Rodio library](https://docs.rs/rodio/0.9.0/rodio/struct.Sink.html)
which actually handles the sounds and you can see that Quicksilver is very limited.
Basically, you can only use Quicksilver for beeps and warbles at the moment. I also found
the asset system annoying: there is no way of checking to see if an asset has finished
loading, or if a sound is currently playing - you have to maintain your own flag.

Quicksilver's sound support is very much minimal-viable-product at the moment.
To fix the sound issues I'm considering just ignoring Quicksilver's sound support and
using Rodio directly. Interestingly, if you delve into
[Quicksilver's asset module](https://github.com/ryanisaacg/quicksilver/blob/master/src/lifecycle/asset.rs)
you can see it also maintains an internal 'loading' state.

And that is
[p4 - commit ca7fbaed80c](https://github.com/PhilipDaniels/eliter/commit/ca7fbaed80c35a6a3c869cddb4b1a3f1aa3d3da9) - the ship parade is working. A small flaw does show up -
if you maximize the window you can see that the corners of the triangles do not always
meet up quite where they should be. I think this is due to the inaccuracies in the 3D
calculations due to the use of integer arithmetic in some places. Converting the whole
thing to use `f32` I suspect will fix it so again, this is something to not worry about
at the moment, it can be done later. And I still need to figure out why the ships are
slightly offset. Not to mention the stars.
