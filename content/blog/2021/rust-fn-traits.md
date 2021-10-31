---
title: "Rust Fn Traits"
date: "2021-10-31"
draft: false
tags: [rust, fn, traits, functions, closures, api]
---

# The Rust Fn Traits

There are 3 traits, defined as follows

```rust
pub trait Fn<Args>: FnMut<Args> {
    extern "rust-call" fn call(&self, args: Args) -> Self::Output;
}

pub trait FnMut<Args>: FnOnce<Args> {
    extern "rust-call" fn call_mut(
        &mut self, 
        args: Args
    ) -> Self::Output;
}

pub trait FnOnce<Args> {
    type Output;
    extern "rust-call" fn call_once(self, args: Args) -> Self::Output;
}
```

[Fn](https://doc.rust-lang.org/std/ops/trait.Fn.html) callables can be called repeatedly
without mutating their argument (they take arguments by `&`).

[FnMut](https://doc.rust-lang.org/std/ops/trait.FnMut.html) callables can be called
repeatedly and may mutate their argument (they take arguments by `& mut`).

[FnOnce](https://doc.rust-lang.org/std/ops/trait.FnOnce.html) callables can be called once
(they take arguments by move).

Note that `FnOnce` is a supertrait of `FnMut`, and `FnMut` is in turn a supertrait
of `Fn`. In other words, *anything that implements `FnMut` must also implement `FnOnce`*, 
and by analogy for `Fn`.

* `FnOnce` is implemented automatically by closures that might consume captured variables, as well as all types that implement `FnMut`.

* Since both `Fn` and `FnMut` are subtraits of `FnOnce`, any instance of `Fn` or `FnMut` can be used where a `FnOnce` is expected.

* Since `FnOnce` is a supertrait of `FnMut`, any instance of `FnMut` can be used where a `FnOnce` is expected, and since `Fn` is a subtrait of `FnMut`, any instance of `Fn` can be used where `FnMut` is expected.

* Use `FnOnce` as a bound when you want to accept a parameter of function-like type and only need to call it once. If you need to call the parameter repeatedly and possibly mutate state, use `FnMut` as a bound; if you also need it to not mutate state, use `Fn`.

# Closure Compilation

When the compiler sees a closure, it creates a closure that allows greatest possible
re-use of variables outside the closure, that is, it favours `Fn`, then `FnMut`, then
`FnOnce` if variables are moved. Actually what happens, is that the compiler
generates implementations of all possible traits for each closure's environment struct.
That is, it will generate

* `Fn`, `FnMut` and `FnOnce`   **or**
* `FnMut` and `FnOnce`   **or**
* `FnOnce`

(This is what allows you to pass an `Fn` callable into a `FnMut` or `FnOnce` API).

As a side note, this means that **all** closures implement `FnOnce`, and hence can
be called once! (or more, depending on type, obviously.)

# API Design

So the question is, when you are designing a function's interface, which should
you use?

* If you use `Fn` as a trait bound, that is the strictest possible - your callers can only call it with closures that take shared referecnes.

* If you use `FnMut` as a trait bound, that is medium-strict - your callers can call it with a closure that takes shared references or mut references.

* If you use `FnOnce` as a trait bound, that is most permissive - your callers can call it with any type of closure possible in Rust. But it might consume non-copy types.

Most of the time when specifying one of the Fn trait bounds, you can start with Fn and the compiler will tell you if you need FnMut or FnOnce based on what happens in the closure body.

The explanation below about why the `map` methods for `Option` and `Iterator`
are different (`FnOnce` and `FnMut` respectively) may well inform your API design. Summary: you have to be careful about *arbitrary captured environment*, not just
the pieces of data your closure may be dealing with directly.


# Examples from the Standard Library

### Examples from the [Iterator trait](https://doc.rust-lang.org/stable/std/iter/trait.Iterator.html)

```rust
/// Tests if every element of the iterator matches a predicate.
fn all<F>(&mut self, f: F) -> bool
where
    F: FnMut(Self::Item) -> bool, 

/// Takes a closure and creates an iterator which calls that closure on each element.
fn map<B, F>(self, f: F) -> Map<Self, F>
where
    F: FnMut(Self::Item) -> B

/// Creates an iterator which uses a closure to determine if an element should be yielded.
fn filter<P>(self, predicate: P) -> Filter<Self, P>ⓘ
where
    P: FnMut(&Self::Item) -> bool

/// Creates an iterator that both filters and maps.
fn filter_map<B, F>(self, f: F) -> FilterMap<Self, F>ⓘ
where
    F: FnMut(Self::Item) -> Option<B>

/// Searches for an element of an iterator that satisfies a predicate.
fn find<P>(&mut self, predicate: P) -> Option<Self::Item>
where
    P: FnMut(&Self::Item) -> bool

/// Calls a closure on each element of an iterator.
fn for_each<F>(self, f: F)
where
    F: FnMut(Self::Item)

/// Creates an iterator that skips elements based on a predicate.
fn skip_while<P>(self, predicate: P) -> SkipWhile<Self, P>ⓘ
where
    P: FnMut(&Self::Item) -> bool    
```

### Examples from [Option&lt;T&gt;](https://doc.rust-lang.org/stable/std/option/enum.Option.html)

```rust
/// Returns None if the option is None, otherwise calls f with the wrapped value and returns the result.
pub fn and_then<U, F>(self, f: F) -> Option<U>
where
    F: FnOnce(T) -> Option<U>

/// Returns None if the option is None, otherwise calls predicate with the wrapped value
/// and returns Some(t) if the predicate returns true.
pub fn filter<P>(self, predicate: P) -> Option<T>
where
    P: FnOnce(&T) -> bool

/// Maps an Option<T> to Option<U> by applying a function to a contained value.
pub fn map<U, F>(self, f: F) -> Option<U>
where
    F: FnOnce(T) -> U
```

Note that, in general, iterators use `FnMut` and options use `FnOnce`. It may be puzzling why `Iterator::map` is `FnMut` rather than `FnOnce` - we are only going
to call it once per item in the iterator, after all.

The answer is that closures can also have an *arbitrary captured environment*, and
we must be careful to restrict what they might do.

An `Option` has at most 1 item, so it's fine for its callables to be `FnOnce` - as that is the most number of times they could possibly be called! On the other hand, iterators have possibly many items, so the closure could be called more than once. 

For example, this closure is `FnOnce`:

```rust
|x| { drop(v); x == 1 }
```

The captured variable `v` is dropped, so this has to be an `FnOnce` - you can't call it twice because you can't drop `v` twice. This would be fine to use on `Option::map`
but inadmissible for `Iterator::map`. In other words, while it might be fine for the closure in `Iterator::map` to take the value *from the iterator* by move, we have to
ensure that the closure can be called multiple times with respect to any other
arbitrary environment that may have been captured.

Since `Iterator::map` takes an `FnMut` this closure which captures `counter` works fine:

```rust
|x| { counter += 1; x == 1 }
```



# Further Reading

[Finding Closure in Rust](https://huonw.github.io/blog/2015/05/finding-closure-in-rust/)


