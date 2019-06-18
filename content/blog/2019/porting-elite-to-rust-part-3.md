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

# Update: WASM no longer works

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





## Heading 2
### Heading 3
#### Heading 4
##### Heading 5

Start your engines...

*This is italic* and **this is bold**, ***this is bold-italic*** and ~~this is strikethrough~~.

[A link](https://www.x.com)

![An image for this post](image1.png)

[Link to another post in this year]({{< ref "other-post.md" >}})
[Link to another post in another year]({{< ref "../2017/"other-post.md" >}})
[Link to a heading]({{< relref "#my-normalized-heading" >}}).

> This is a quote

Use 4 spaces to create pre-formatted text:

    $ some example text for example with <b> tags

A list is created using asterisks or dashes

* First
* Second
* Third

