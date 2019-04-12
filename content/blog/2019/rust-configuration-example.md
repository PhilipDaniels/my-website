---
title: "An Ergonomic Approach to Configuration in Rust"
date: "2019-04-12"
draft: false
tags: [rust, configuration, clap, options, lazy_static]
---

# Ergonomic Configuration

In most of the programs I have written so far the configuration consists of a combination of defaults,
optional settings from configuration files, and command line options, in that order of precedence.

And once established, it is usually immutable.

Setting this up is not difficult, but it helps to have a worked example, as otherwise it
is easy to get lost in what to call things.

I have created a [worked example](https://github.com/PhilipDaniels/rust-config-example)
which has the following features:

* Uses [lazy_static](https://crates.io/crates/lazy_static) to create a global, singleton
  `Configuration` struct which is initialized with the merging of all the different
  possible sources of configuration.
* Because it is global, you don't need to pass it down through method chains.
* If the command line options are bad, the program terminates, thanks to
  [clap](https://crates.io/crates/clap).
* The `Configuration` in this example is immutable, which makes for a safe singleton.
  This works for most of my programs. If you want some mutability, consider interior
  mutability.
* This approach lends itself to decomposition - there is no need to have just
  one big `Configuration` struct, you could not have several dealing with different
  concerns.

## The downside of ease-of-use

I call it ergonomic because it removes the need to pollute your method signatures with
`&Configuration`  parameters. The downside to this is that your methods now depend on
*ambient context* which you can't tell just from looking at your method
signatures, you need to inspect the code inside to discover this (according to the
principles of Dependency Injection this is a **bad thing** and your method signatures
or constructors should always make your dependencies apparent). However for some kinds
of programs it is a reasonable trade-off.

If this bothers you, you can still use the worked example as a starting point. Just
remove the `lazy_static` and return the `Configuration` object and bind it to
a local variable at the beginning of main:

```rs
fn main() {
    let config = Configuration::new();
    /// Now pass &config, or sub-parts of config, into the methods that need them.
}
```
