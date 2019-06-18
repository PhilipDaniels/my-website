---
title: "Porting Elite to Rust, Part 2"
date: "2019-06-16"
draft: true
tags: [rust, elite, gaming, quicksilver, webasm]
---

# Display a ship

It seemed that the next milestone ought to be to display a ship and run the first intro
screen.

Alas, this is where the idea of porting things gradually falls down a bit - displaying a ship
involves standing up pretty much the entire 3D system of **Elite: The New Kind** as well as the
configuration system and deciding how to map some important C constructs such as the many
`#define` constants and module-level data that is associated with a particular function.

When I began I wasn't sure which data is needed where or how best to represent that in Rust
so I decided to just wing it, and refactor aggressively as I went on and developed a better
understanding of the code base. My initial thoughts didn't go much further than 'put all
the data under the `GameState` structure, using appropriate sub-subtructures to organise
things logically'.

I also decided that I would try to port to Rustish code rather than keeping everything a
direct analogue of the C code. For example, the `SHIP_*` constants which define the possible
ships became a Rust enum. In the Elite world, 'ship' also means *planet*, *rock* or *missile*,
basically any type of object in the universe. There are also a lot of places in the C
code where fixed-size arrays are used, either as simple arrays or as linked lists. I ported
these over initially as-is, then refactored them into vectors as I found both the fixed
sized-ness and having to pass around separate length variables quite annoying. This does
mean that my code allocates more than ETNK, but I prefer it this way. We'll see if performance
is a problem later on when more of the game is running.

# Minor annoyances

You can't index arrays using enums, even if they are represented as usize. This was rather
annoying at first, needing `[ship_type as usize]` expressions everywhere. Realizing that
I could just do this made the code a lot more ergonomic:

```rs
impl Index<ObjectType> for ShipList {
    type Output = ShipData;
    fn index(&self, idx: ObjectType) -> &ShipData {
        assert!(idx != ObjectType::Nothing && idx != ObjectType::Sun && idx != ObjectType::Planet);
        &self.ships[idx as usize]
    }
}
```

Still, we are left with a lot of casts due to u32/i32/usize/f32 differences.

ETNK stores the definitions of its ships as a bunch of constant struct definitions, they are
not stored in separate data files. In C they are all const, but trying to port the `SHIP_FLAGS`
structure I found a
[deficiency](https://github.com/bitflags/bitflags/issues/180)
in the
[bitflags](https://crates.io/crates/bitflags) crate. This won't work:

```rs
bitflags! {
    pub struct FLAGS: u8 {
        const ANGRY  = 1;
        const BOLD = 2;
    }
}

const MAMBA_FLAGS: FLAGS = FLAGS::ANGRY | FLAGS::BOLD;
```

It fails on the `BitOr` operator. I'm working around it by inserting the appropriate flags into
a lazy static hashmap.

# Importing the data

Drawing a ship requires importing all the ship struct definitions from `shipdata.c` and `shipface.c`.
I hand-translated the first set, for the missile, but this soon got tedious. So I hacked the
original C source code to `printf` all its internal data structures in Rust source code format.
I was quite pleased with this hack as it meant there would be no transcription errors - and it
constitutes 25% of the entire code base ported! The branch is `f-dump-ship-data` in ETNK. It results
in a lot of Rust code like this:

```rs
static MISSILE_POINT: [ShipPoint; 17] = [
    ShipPoint { x:    0, y:    0, z:   68, dist:   31, face1:  1, face2:  0, face3:  3, face4:  2 },
    ShipPoint { x:    8, y:   -8, z:   36, dist:   31, face1:  2, face2:  1, face3:  5, face4:  4 },
    ShipPoint { x:    8, y:    8, z:   36, dist:   31, face1:  3, face2:  2, face3:  7, face4:  4 },
    ShipPoint { x:   -8, y:    8, z:   36, dist:   31, face1:  3, face2:  0, face3:  7, face4:  6 },
    ...
];
```

I also needed to bring in colors. Colors in ETNK are just defined like this:

```c
#define GFX_COL_BLUE_1		45
```

They are indexes into a palette stored in `scanner.bmp`. I couldn't see a way of accessing
that palette using Quicksilver, so I extracted it by loading
the BMP into Gimp and doing 'Export As -> C source code header`. This resulted in something
close to Rust, and with the aid of this macro to convert the ETNK bytes into the floating point
values required by Quicksilver:

```rs
macro_rules! color {
    ($r:expr, $g:expr, $b:expr) => ({
        Color { r: $r as f32 / 256.0, g: $g as f32 / 256.0, b: $b as f32 / 256.0, a: 0.0 }
    });
}
```

I was able to define my own palette as a static variable:

```rs
static PALETTE: [Color; 256] = [
    color!(  0,  0,  0),
    color!(128,  0,  0),
    color!(  0,128,  0),
    ...
];


pub static GFX_COL_BLACK: Color = PALETTE[0];
pub static GFX_COL_DARK_RED: Color = PALETTE[28];
```

# Standing up the 3D system

I won't bore you with all the details - suffice it to say that I started at the top, with the
call to `add_new_ship` to create a Cobra3 for the first intro screen, and drilled down
from there:

```rs
game_state.universe.add_new_ship(
    ObjectType::Cobra3,
    0, 0, 4500,
    &m,
    -127, -127
    );
```

(Yes the ship/object dichotomy is annoying).

With the ship in place, the next step was to try and draw it.

This is where things went a little awry. Porting the 3D math is pretty much an all-or-nothing
affair, you only really know it's working when you see a ship on screen. I also hit another
problem with Quicksilver - there is no way to draw a polygon on the screen. Lines, rectangles,
circles, sure, but for a polygon with an arbitrary number of points you have to reach for the
'mesh' API. This took some figuring out, the documentation is still a work-in-progress. It feels
like a polygon object really ought to be exposed as a first-rank API. I also found a
[bug in Quicksilver](https://github.com/ryanisaacg/quicksilver/issues/505)
which means the order that you draw things in can affect whether anything appears at all. This
was one of the factors contributing to the fact that my first effort to draw a ship showed
nothing at all! I also discovered that debugging games is quite hard...

Eventually I resorted to adding logging to the low-level `gfx_polygon` function in `graphics.rs`.
(All the higher-level 'draw' routines don't in fact drawing anything to the window, they just
calculate polygons.)

With this I discovered that my polygons were all tiny, with points almost on top of each other.
I hacked in a large red square and confirmed it was displaying OK, so I thought I had found
the problem. Indeed, if you watch the first intro in a pukka copy of ETNK you can see that the
ship starts off very far away and moves towards the camera. I don't have any ship movement
programmed yet, so I changed the depth of the initial ship creation from 4500 to 150. Still
no luck. I also hand-checked all the vector arithmetic and found a couple of bugs. This
one was a surprise to me - given:

```rs
pub fn unit(&self) -> Self {
    let lx = self.x;
    let ly = self.y;
    let lz = self.z;

    let uni = (lx * lx + ly * ly + lz * lz).sqrt();

    Self {
        x: lx / uni,
        y: ly / uni,
        z: lz / uni
    }
}
```

a call such as

```rs
v.unit();
```

does not generate a warning! I had such a call in my code and hence was simply throwing
away the result. You would think that Rust would generate a warning here, as calling a
`(&self)` method and throwing away the result is a complete no-op. I added `#[must_use]`
to the method to make a warning appear.

I went over the code several times and the maths all seemed to be working OK now, and
the polygons were no longer minuscule and SHOULD be appearing on the screen, but still
nothing was appearing. Finally, I added some more logging to `gfx_polygon` and found
the error. It's in the `color` macro above. Go take a look. I'll wait. Spot it?

<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>

Yes, defining all your colors with an alpha value of 0 results in nothing appearing
on the screen! Change it to 1 and hey presto! we get a ship:

![Display Cobra3](p2_display_cobra.png)

Not one of my finer moments, but very satisfying to get to the bottom of it!
The eagle-eyed will notice that the ship is not quite in the horizontal center, so something
is still not quite right, still, it looks reasonable.

# Take-aways

The code when this blog point was written is at tag 'p2', commit
[65bac242b](https://github.com/PhilipDaniels/eliter/commit/65bac242b1bcea82703a399eac9cfb4da626ef5c).

`#[allow(dead_code)]` at module-level is very useful while stubbing out to prevent
RLS from turning a large fraction of your code base green with squigglies.

Debugging games is very difficult when your 3D isn't working!

I setup debugging in
[VS Code using this blog post](https://www.forrestthewoods.com/blog/how-to-debug-rust-with-visual-studio-code/)
and got logging working while debugging using
[env_logger](https://crates.io/crates/env_logger)
and setting appropriate
[environment variables](https://github.com/vadimcn/vscode-lldb/blob/master/MANUAL.md#starting-a-debug-session)

# Next Steps

Animation of the ship. Frame rates.

