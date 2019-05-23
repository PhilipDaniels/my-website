---
title: "[DRAFT] Reading Rust"
date: "2019-04-14"
draft: true
tags: [rust, syntax, generics]
---

# Introduction

This article is a summary of the more difficult/esoteric/strange elements of Rust
syntax. To be sure, some of the examples here are reasonably common and familiar
to everyone who has gone beyond beginner level, but I include them to help point the
way towards the more challenging examples!

# Generics and traits

**Generic impl block** Implements a trait (WriteHtml) for a whole set of types

```rs
impl<W: Write> WriteHtml for W { ... }
```

**Trait object parameter vs generics** Favour generics, use trait objects only for heterogeneous collections
or boxed return parameters. Also, traits which use `Self` can't be trait objects anyway, so you are
pushed towards using generics for all but the simplest uses.

```rs
fn say_hello(out: &mut Write);        // Trait object, uses dynamic dispatch
fn say_hello<W: Write>(out: &mut W);  // Generic, uses static dispatch
```

**Where clause for multiple generic constraints** Usually best to extract these onto their own line

```rs
fn top_ten<T>(values: &[T]) -> Vec<&T>
where T: Debug + Hash + Eq
```

**Lifetimes and type parameters** Lifetimes always come first

```rs
fn nearest<'t, 'c, P>(target: &'t P, candidates: &'c [P]) -> &'c P
```

**Self in trait definitions** IMPORTANT! Using `Self` in a trait definition makes it impossible
to use that trait as a trait object. You can only use it as a generic. See *Programming Rust*[^1], p250.

```rs
trait Spliceable {
    // Can't use as a trait object (because self and other could be different types)
    fn splice(&self, other: &Self) -> Self;
}

trait MegaSpliceable {
    // Fixed. self and other can be different types and we return another trait object.
    fn splice(&self, other: &MegaSpliceable) -> Box<MegaSpliceable>;
}
```

**Subtraits** Add more methods or constraints to a trait. Every type that implements `Ord` must
also implement `PartialOrd` - in two separate `impl` blocks.

```rs
trait Ord : PartialOrd { ... }
```

**Static methods in traits** Omitting `self` gives you a static, just like when using an `impl`
block to add methods to a type.

```rs
trait StringSet {
    fn new() -> Self;
    fn from_slice(strings: &[&str]) -> Self;
}

// Call static from non-generic code (assume we have 'impl StringSet for SortedStringSet')
let set1 = SortedStringSet::new();
// Call static methods in generic code using the type variable
fn foo<S: StringSet>() {
    let set1 = S::new();
}
```

*Trait objects* do not support static methods. The trait `StringSet` can be made to allow
trait objects by adding a `Sized` bound to each static method:

```rs
trait StringSet {
    fn new() -> Self
    where Self: Sized;
    fn from_slice(strings: &[&str]) -> Self
    where Self: Sized;
    ...
```

After doing that, trait objects are allowed but they still won't have the static methods.
Generic uses of the trait will have the static methods.







[^1]: Programming Rust by Jim Blandy and Jason Orendorff, O'Reilly Media, ISBN 978-1-491-92728-1