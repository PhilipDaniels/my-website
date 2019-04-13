---
title: "Hand-Implementing PartialEq, Eq, Hash, PartialOrd and Ord in Rust"
date: "2019-04-13"
draft: false
tags: [rust, partialeq, eq, hash, partialord, ord, equality, identity]
---

# Introduction

This article is a short how-to guide for writing your own implementations of
the equality, hashing and ordering traits in Rust. Often you can just auto-derive
these:

```rs
#[derive(PartialEq, Eq, Hash, PartialOrd, Ord)]
pub MyStruct {
    ...
}
```

But sometimes you want to roll your-own, perhaps because you can do it more
efficiently than the automatic versions, or you simply want to be more explicit
about what it means for two things to be 'equal' or perhaps you want to express
relationships between instances of `MyStruct` and `SomeOtherStruct`, which the
automatic versions can't do.

In this article, I will use this simple struct as an example:

```rs
#[derive(Debug, Default, Clone)]
pub struct FileInfo {
    pub path: PathBuf,
    pub contents: String,
    pub is_valid_utf8: bool,
}
```

It represents the contents of some text file located at `path` with the contents
loaded as a string and a flag to indicate whether the contents were valid UTF-8.

In the context in which this structure is used, the `path` is always unique - a file is
only loaded into memory once. I like to think of Rust data in entity-relationship modelling
terms: `path` acts like a primary key and the other fields of the struct are determined
attributes. The concept of identity is therefore encapsulated solely by the `path` - if two
paths are equal, then the two `FileInfos` will also be equal.


# Equality: the PartialEq and Eq traits

If you want to express what it means for values of your types to be equal, you must
implement the
[PartialEq](https://doc.rust-lang.org/std/cmp/trait.PartialEq.html) trait.
Implementing it allows us to write `x == y` and `x != y` for our types.

For `FileInfo` it is easily implemented simply by delegating to the `path` member's
implementation of `PartialEq`:

```rs
impl PartialEq for FileInfo {
    fn eq(&self, other: &Self) -> bool {
        self.path == other.path
    }
}
```

Optionally you can (and usually should) also implement the
[Eq](https://doc.rust-lang.org/std/cmp/trait.Eq.html) trait.

The definition of this trait is empty, containing no methods:

```rs
trait Eq: PartialEq<Self> {}
```

However it is not useless - it is a sort of marker trait which makes your types
usable as keys in hashmaps.

You can implement it manually with an empty `impl` block

```rs
impl Eq for FileInfo {}
```

But it's easier to just add `Eq` to your `#[derive(Eq)]` list.

When would you **NOT** implement `Eq`? Very rarely. `Eq` is an
[equivalence relation](https://en.wikipedia.org/wiki/Equivalence_relation)
and hence requires the three properties of

* [transitivity](https://en.wikipedia.org/wiki/Transitive_relation) if `x == y` and `y == z` then `x == z`
* [symmetricness](https://en.wikipedia.org/wiki/Symmetric_relation) if `x == y` then `y == x`
* [reflexivity](https://en.wikipedia.org/wiki/Reflexive_relation) `x == x` is always true

*to be satisifed for all `x` in the domain*.

These properties hold for most data. The main exception - and the only exception in the Rust
standard library - is floating point values, where `NaN` enters the picture and screws things up -
the reflexivity property does not hold, because the IEEE floating point standard requires that `NaN`
is not equal to itself (or any other number too).

> **TL;DR** If you implement PartialEq then #[derive(Eq)] as well unless you can't

# Hashing

Hashing a value is closely related to the concept of equality, such that if you implement
your own `PartialEq` you should also implement the
[Hash](https://doc.rust-lang.org/std/hash/trait.Hash.html) trait.

> The following must hold: if `x == y` then `hash(x) == hash(y)`

Your values won't work properly as keys in
[HashMaps](https://doc.rust-lang.org/std/collections/struct.HashMap.html)
and
[HashSets](https://doc.rust-lang.org/std/collections/struct.HashSet.html)
if you violate this principle.


It says that if two values are equal according to `PartialEq` then they should have the same hash code.
The converse **DOES NOT** hold - the fact that two values have the same hash code **DOES NOT**
imply that they are equal. When this happens we are said to have a 'hash collision' and they
are inevitable in some domains because there are many more possible values than there are
distinct `u64` values (hash codes are `u64s`). As a trivial example, a struct with two `u64`
members has `u64::MAX * u64::MAX` possible values which is far greater than `u64::MAX`. Therefore
it's not possible to map all instances of such structs to their own unique hash code.

We can implement `Hash` in a very similar way as we did for `PartialEq`, by delegating the
responsibility for calculating it down to the `path` member:

```rs
impl Hash for FileInfo {
    fn hash<H: Hasher>(&self, hasher: &mut H) {
        self.path.hash(hasher);
    }
}
```

This delegation technique will work for all types, since all the fundamental types in the
standard library implement `PartialEq` and `Hash`.

# Ordering: the PartialOrd and Ord traits

The relative ordering of values is calculated using the operators `<`, `<=`, `>=` and `>`.
To implement these for your own types you must implement the
[PartialOrd](https://doc.rust-lang.org/std/cmp/trait.PartialOrd.html)
trait.

> Before you can implement `PartialOrd` you must implement `PartialEq` first.

Here is an example.

```rs
impl PartialOrd for FileInfo {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.path.partial_cmp(&other.path)
    }
}
```

[Ordering](https://doc.rust-lang.org/std/cmp/enum.Ordering.html) is a simple enum with these
values:

```rs
pub enum Ordering {
    Less,
    Equal,
    Greater,
}
```

You may be wondering why `partial_cmp` returns an `Option` and not just a plain `Ordering`.
It's to do with floats again - because [NaNs](https://en.wikipedia.org/wiki/NaN) are not
representable numbers, expressions such as `3.0 < NaN` don't make any sense. In those cases,
`partial_cmp` returns `None`. Floating point values are the only case in the standard
library where this happens.

The fact that `partial_cmp` returns an `Option<Ordering>` has a consequence: it might not
be possible to place two values, `x` and `y`, into a definite order. In practice, this means
that implementing `PartialOrd` is not sufficient to make your values sortable. You also
need to implement the [Ord](https://doc.rust-lang.org/std/cmp/trait.Ord.html) trait.

> To enable your values to be sorted, you must implement **Ord**

> Before you can implement **Ord**, you must first implement **PartialOrd**, **Eq** and **PartialEq**

For our `FileInfo` struct, again we can delegate down to our member variables:

```rs
impl Ord for FileInfo {
    fn cmp(&self, other: &Self) -> Ordering {
        self.path.cmp(&other.path)
    }
}
```

With that in place, sorting a `Vec<FileInfo>` now works.


# Extending to more than one member

You may be wondering how to implement the above traits if you need to compare more than one
member of your value (in entity-relationship terms, if we have a compound primary key). The
following pattern works:

```rs
impl PartialEq for ExtenededFileInfo {
    fn eq(&self, other: &Self) -> bool {
        // Equal if all key members are equal
        self.path == other.path &&
        self.attributes == other.attributes
    }
}

impl Hash for FileInfo {
    fn hash<H: Hasher>(&self, hasher: &mut H) {
        // Ensure we hash all key members.
        self.path.hash(hasher);
        self.attributes.hash(hasher);
    }
}
```

Ordering is a little trickier - you need to compare the first field, if the result is not `Equal` you
are done, but if it is `Equal` you need to move onto the next field, and so on. Left as an exercise
for the reader!


# Extending to comparisons between different types

I glossed over something in the above discussion. In every case, I was comparing a `FileInfo`
to another `FileInfo`. But this doesn't have to be the case. The traits take a type
parameter called `Rhs` - short for 'right hand side' - which allows you to compare a `FileInfo`
to a `Path` (say) or (more usefully) a complex number to an `f64`. (`Ord` is a counterpoint to
this observation: both `self` and `Rhs` must be of the same type.)

`Rhs` didn't show up in the code examples above because it is defaulted to be the same type
as `Self`. Here is the full definition of `PartialEq` from the standard library:

```rs
pub trait PartialEq<Rhs: ?Sized = Self> {
    fn eq(&self, other: &Rhs) -> bool;
    fn ne(&self, other: &Rhs) -> bool { !self.eq(other) }
}
```

To enable cross-type equality comparisons, in this case between `FileInfo` and `&str`,
you would do something like this:

```rs
impl PartialEq<&str> for FileInfo {
    fn eq(&self, other: &&str) -> bool {
        match self.path.to_str() {
            Some(s) => s == *other,
            None => false
        }
    }
}
```

Note that the `other` parameter in `eq` is always defined to be a shared reference to something,
so that when we implement it for `&str` we end up with a double reference, which we then have
to de-reference once to make the `s == *other` comparison.

# A note on efficiency

You may be wondering - is it more efficient to hand-craft your own implementations of these
traits or use the auto-derived ones? It's hard to say. If you know that you only have a
few fields that are relevant from a large struct, then you may well be able to beat the
auto-derived implementations. On the other hand, although the auto-derived code may
examine every field in your struct, it uses short-circuiting boolean expressions so it may
well stop after looking at the first field (say `path` in `FileInfo`) and hence be just as
fast in practice.

The auto-derived code also has two other tricks up its sleeves. Firstly, it generates
custom implementations for **all** the methods in the traits, including those that have default
implementations. For example, for `PartialOrd` it doesn't just generate `partial_cmp` but
`lt`, `le`, `ge` and `gt` as well. Secondly, it adds `#[inline]` to all its methods.

You can use the [cargo expand](https://github.com/dtolnay/cargo-expand) utility to
dump the generated code to stdout. Try it on the program below by removing some of
the custom implementations and `#[derive]` them instead.


# Complete Program

```rs
use std::path::PathBuf;
use std::hash::{Hash, Hasher};
use std::collections::HashMap;
use std::cmp::Ordering;

#[derive(Debug, Default, Clone, Eq)]
pub struct FileInfo {
    pub path: PathBuf,
    pub contents: String,
    pub is_valid_utf8: bool,
}

impl FileInfo {
    fn new<P: Into<PathBuf>>(path: P) -> Self {
        Self {
            path: path.into(),
            ..Default::default()
        }
    }
}

impl PartialEq for FileInfo {
    #[inline]
    fn eq(&self, other: &Self) -> bool {
        self.path == other.path
    }
}

impl Hash for FileInfo {
    #[inline]
    fn hash<H: Hasher>(&self, hasher: &mut H) {
        self.path.hash(hasher);
    }
}

impl PartialOrd for FileInfo {
    #[inline]
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.path.partial_cmp(&other.path)
    }
}

impl Ord for FileInfo {
    #[inline]
    fn cmp(&self, other: &Self) -> Ordering {
        self.path.cmp(&other.path)
    }
}

impl PartialEq<&str> for FileInfo {
    #[inline]
    fn eq(&self, other: &&str) -> bool {
        match self.path.to_str() {
            Some(s) => s == *other,
            None => false
        }
    }
}

fn main() {
    // Demonstrate the various traits. Try commenting out the `impl`
    // blocks to see the various compilation errors you get when they
    // are not implemented.

    let f1 = FileInfo::new("/temp/foo");
    let f2 = FileInfo::new("/temp/bar");

    // ------------------------------------------------------------------------------
    // Demonstrate PartialEq. It gives us `==` and `!=`.
    if f1 == f2 {
        println!("f1 and f2 are equal");
    } else {
        println!("f1 and f2 are NOT equal");
    }

    if f1 != f2 {
        println!("f1 and f2 are NOT equal");
    } else {
        println!("f1 and f2 are equal");
    }

    // ------------------------------------------------------------------------------
    // Demonstrate Hash. Note that the HashMap takes ownership of its keys -
    // they are moved into the HashMap.
    let mut hm = HashMap::new();
    hm.insert(f1, 200);
    hm.insert(f2, 500);
    // To avoid complicating this discussion, make a new FileInfo to perform a lookup.
    // In real-life, you would implement the Borrow trait to avoid the temporary variable.
    let f_lookup = FileInfo::new("/temp/foo");
    let file_size = hm[&f_lookup];
    println!("f1 has a size of {} bytes", file_size);

    // ------------------------------------------------------------------------------
    // Demonstrate PartialOrd. It gives us `<`, `<=`, `>=` and `>`.

    // Makes some new f's because the others went into the HashMap.
    let f1 = FileInfo::new("/temp/foo");
    let f2 = FileInfo::new("/temp/bar");

    if f1 < f2 {
        println!("f1 is less than f2");
    } else {
        println!("f1 is not less than f2");
    }

    if f1 > f2 {
        println!("f1 is greater than f2");
    } else {
        println!("f1 is not greater than f2");
    }

    // ------------------------------------------------------------------------------
    // Demonstrate Ord. It unlocks sorting functionality.
    let mut v = vec![f1, f2];
    v.sort();
    println!("v after sorting = {:#?}", v);

    // ------------------------------------------------------------------------------
    // Demonstrate cross-type equality testing.
    let f1 = FileInfo::new("/temp/foo");
    if f1 == "/temp/foo" {
        println!("The path in f1 is equal to the str value \"/temp/foo\"");
    } else {
        println!("Nope, comparisons to strings are not working as they should be.");
    }
}
```

