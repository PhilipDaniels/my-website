---
title: "Turbo-Charging Rust Release Mode Builds"
date: "2019-04-14"
draft: false
tags: []
---

# Configuring the release profile

Here are some settings you can specify in `Cargo.toml` for fastest possible Release mode builds.
Expect these changes to make marginal differences (5-10%? YMMV).
If you are using a workspace you should specify this in the top-level `Cargo.toml` only.

```toml
[profile.release]
# Enable link-time optimization, eliminates more code and inlines across crate boundaries.
# Default: false
lto = true

# codegen-units of 1 gives best optimization, but disables parallel building.
# Default: 16
codegen-units = 1

# Includes debug information in release builds. Necessary for profiling. Does not
# slow down the executable.
debug = true

# The default optimization level is 3 for release mode builds.
# 0 means disable optimization and is the default for debug mode buids.
# (Setting opt-level=1 for debug builds is a good way of speeding them up a bit.)
# "s" means optimize for size, "z" reduces size even more.
opt-level = 3
```

In addition, if you only care about running on your PC, you can instruct Cargo and rustc to
produce a native binary. The easiest way to do this on a 'one-off' basis is

```bash
RUSTFLAGS="-C target-cpu=native" cargo build --release
```

To check that it's working add a `--verbose` flag to the cargo command.

You may want to set RUSTFLAGS in your `~/.profile`.

On Windows, in PowerShell you set an environment variable in two steps (use
`echo $env:RUSTFLAGS` to check it's set):

```powershell
$env:RUSTFLAGS="-C target-cpu=native"
cargo build --release
```

This will set RUSTLFAGS temporarily, for that PowerShell session only: if you start
a new PowerShell window you will need to set it again. You can use the
`System Properties -> Environment Variables` window to set it permanently.

Alternatively you can set RUSTFLAGS in `.cargo/config`, see below for an example.

[Cargo manifest format](https://doc.rust-lang.org/cargo/reference/manifest.html)

[Speed vs size](https://rust-embedded.github.io/book/unsorted/speed-vs-size.html)

# Getting better performance from Development mode builds

There is a neat trick you can use to get Cargo make your Development mode
builds run faster, potentially giving you faster run times while keeping
compilation times reasonable. If you add the following to your `Cargo.toml`,
it will make Cargo *compile all your crate dependencies with full optimisations*
(like in Release mode) but
compile your own code with fewer optimisations (like in Development mode).
Best of both worlds? Maybe.
As the [Cargo profiles](https://doc.rust-lang.org/cargo/reference/profiles.html#overrides-and-generics) page shows, if you make heavy use of generics from 3rd party crates then you
won't get the full benefit, but in most cases I would not be surprised if
90% of the Rust code in your program is actually from crates. It certainly
worked fantastically well on a game I was writing.

```toml
# Set the default for dependencies.
[profile.dev.package."*"]
opt-level = 3

[profile.dev]
# Turn on a small amount of optimisation in development mode.
opt-level = 1
```

# Creating a config file for Cargo

You can create a `config` file for Cargo to specify defaults for these settings.

This file can reside either in your crate's directory, or any parent thereof. In
particular, if your source code is under your home directory, you can create
a 'global' default in `~/.cargo/config`. [See here](https://doc.rust-lang.org/cargo/reference/config.html)
for the actual directory search order.

Typical contents might be:

```toml
[target.'cfg(any(windows, unix))']
rustflags = ["-C target-cpu=native"]

[profile.release]
lto = true
codegen-units = 1
debug = true
opt-level = 3
```

However, at the time of writing there is a significant downside. You'll soon
discover that `cargo build --release` won't work, and you are told to use
`cargo build --release -Z config-profile` but that won't work either unless you
are on the nightly channel of cargo! Annoying.

Probably best to stick to pasting it into your `Cargo.toml`.
