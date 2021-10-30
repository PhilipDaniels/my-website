---
title: "Design of Rust APIs (AsRef, Into, Cow)"
date: "2019-04-06"
draft: false
tags: [rust, api, cow]
---

# Flexible Input Parameters

There are two generic built-in traits you can use to make your function easy to call.

They are [AsRef](https://doc.rust-lang.org/std/convert/trait.AsRef.html)
and [Into](https://doc.rust-lang.org/std/convert/trait.Into.html).

## AsRef (and AsMut)

AsRef allows a function to be called with parameters of differing types - basically anything
that allows a reference of the appropriate type to be created cheaply and without ever
failing. [AsMut](https://doc.rust-lang.org/std/convert/trait.AsMut.html)
is the same but for mutable references.

Example:

```rs
fn func1(p1: PathBuf);
fn func2(p1: &Path);

fn func3<S>(p1: S)
where S: AsRef<Path>
{
    let p1 = p1.as_ref();
    ...
}
```

* `func1` can only be called with a `PathBuf`.
* `func2` can be called with a `Path` or a `&PathBuf`.
* `func3` can be called with a `Path` or a `&PathBuf` or anything else
  that allows a `Path` to be borrowed from it - including, handily, strings.

`func3` is therefore most flexible and the best approach.

Consider `func4`:

```rs
fn func4<S>(p1: S, p2: S)
where S: AsRef<Path> { ... }
```

This works, *but constraints `p1` and `p2` to be of the same type. You can be
more flexible:

```rs
fn func4<N, M>(p1: N, p2: M)
where N: AsRef<Path>,
      S: AsRef<Path> { ... }
```

### AsRef`<str`>

One very common case is converting things to (static) strings, for example
enum values. Use the built-in trait for this, do not define your own:

```rs
impl AsRef<str> for XmlDoc {
    fn as_ref(&self) -> &str {
        match self {
            XmlDoc::Unknown => "Unknown",
            XmlDoc::None => "None",
            XmlDoc::Debug => "Debug",
            XmlDoc::Release => "Release",
            XmlDoc::Both => "Both",
        }
    }
}
```

**An AsRef Anti-pattern**

AsRef is useful where you only need to borrow the input parameter. If you find yourself
doing

```rs
let x = param.as_ref().to_owned();
```

You're doing it wrong. Use [Into](https://doc.rust-lang.org/std/convert/trait.Into.html) instead.

## Into
[Into](https://doc.rust-lang.org/std/convert/trait.Into.html)
has a similar effect to AsRef, in that it makes function APIs more flexible. The difference
is that Into is used when you want to **take ownership** of the parameter. This is often used in
constructors, for example:

```
fn new<S>(model: S) -> Self
where S: Into<String>
{
    ...
}
```

You can mix AsRef and Into as required.

* For AsRef<T>, T is the borrowed type (str, Path)
* For Into<T>, T is the owning type (String, PathBuf)

### Getting 'Into' working for your own types
**Do not** implement `Into` for your types. Implement
[From](https://doc.rust-lang.org/std/convert/trait.From.html)
instead. The standard library has a blanket implementation of `Into` which you will get 'for free'.

**If your type has a constructor taking a single parameter of type T**, strongly consider
removing the ctor and implementing `From<T>` instead. Example follows - note that you can still use
`Into` in the implementation for maximum flexibility but you seem to have to use a `where` constraint
to get it to compile:

```rs
impl<P> From<P> for SolutionDirectory
where P: Into<PathBuf>
{
    fn from(sln_directory: P) -> Self {
        SolutionDirectory {
            directory: sln_directory.into(),
            solutions: vec![]
        }
    }
}


let s: SolutionDirectory = "somepath".into();
```


# Misc Observations

* Functions in [std::fs](https://doc.rust-lang.org/1.29.1/std/fs/struct.File.html)
  typically take a `AsRef<Path>` to which you can pass a `PathBuf`,
  `Path`, `String`, `&str`, `OsString` and `OsStr` among others.
* `Into<String>` will take the usual string types plus `Box<str>`, `Rc<String>`,
  `Cow<str>` etc.
* There is little difference between `&str` and `AsRef<str>`. `&str` might be
  [more idiomatic](https://stevedonovan.github.io/rustifications/2018/09/08/common-rust-traits.html) -
  see section 'Reference Conversions - AsRef'.
* The above traits must not fail. Coming soon are
  [TryFrom](https://doc.rust-lang.org/std/convert/trait.TryFrom.html)
  and
  [TryInto](https://doc.rust-lang.org/std/convert/trait.TryInto.html).



# Cow for Out Parameters

[Cow](https://doc.rust-lang.org/std/borrow/enum.Cow.html)
allows you to put off allocation unless it is absolutely necessary.
It often appears in the return position (because it implements DeRef coercion
so there is no need for it in the input parameter list).

A few examples. The `.into()` call is a call to Cow's into method -
basically an easy and ergonomic way of creating Cows without having to
specify `Cow::Borrowed(data)` or `Cow::Owned(data)` everywhere.


```rs
use std::borrow::Cow;

/// Returns a Cow::Borrowed with static lifetime
fn func5() -> Cow<'static, str> {
    "".into()
}

/// Returns a Cow::Owned with static lifetime
fn func6() -> Cow<'static, str> {
    let s = "s".to_owned();
    s.into()
}

/// Returns a Cow::Borrowed with lifetime the same as 'data'.
fn func7(data: &str) -> Cow<str> {
    Cow::Borrowed(&data[0..1])
}

// Ditto.
fn func8(data: &str) -> Cow<str> {
    data[0..1].into()
}

fn main() {
    match func8("hello") {
        Cow::Borrowed(_) => println!("It's borrowed"),
        Cow::Owned(_) => println!("Owned!"),
    }
}
```

# See Also

* [The Official Rust API Guidelines](https://rust-lang-nursery.github.io/api-guidelines/about.html)
* [Elegant Rust APIs](https://deterministic.space/elegant-apis-in-rust.html)
* [Herman Radtke on Cow](https://hermanradtke.com/2015/05/29/creating-a-rust-function-that-returns-string-or-str.html)
* [Combining Into and Cow](https://jwilm.io/blog/from-str-to-cow/)

