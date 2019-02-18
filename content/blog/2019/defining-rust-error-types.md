---
title: "Defining Rust Error Types"
date: "2019-02-18"
draft: false
tags: [rust, errors]
---

# Defining your own error type

When starting a new project, defining your own error type up-front is a good thing to do.
It will result in more ergonomic code, as you can return the same error type from most
functions and can get it to work with the `?` operator. This is especially important if
you use external crates and want to 'amalgamate' their error types.

The strategy defined here is the **TL;DR** summary of a blog post by Rustmeister [BurntSushi](https://blog.burntsushi.net/rust-error-handling/).
It doesn't use any external 'error helper' crates.

## Step 1 - define a custom error type

This type is a union of all possible error types your program needs to handle:

```rs
#[derive(Debug)]
pub enum MyErrorType {
    // Errors from external libraries...
    Io(io::Error),
    Git(git2::Error),
    // Errors raised by us...
    Regular(ErrorKind),
    Custom(String)
}

#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum ErrorKind {
    NotFound,
    NotAuthorized,
    // etc

impl ErrorKind {
    fn as_str(&self) -> &str {
        match *self {
            ErrorKind::NotFound => "not found",
            ErrorKind::NotAuthorized => "not authorized"
        }
    }
}
```

This 'kind enum' design is used by the [Rust standard IO library](https://doc.rust-lang.org/src/std/io/error.rs.html#66-68).
The `as_str` will help in the next step.

## Step 2 - Implement 'Error' and 'Display' traits

Unfortunately `Error` is limited to returning a static string constant:

```rs
impl Error for MyErrorType {
    fn description(&self) -> &str {
        match *self {
            MyErrorType::Io(ref err) => err.description(),
            MyErrorType::Git(ref err) => err.description(),
            MyErrorType::Regular(ref err) => err.as_str(),
            MyErrorType::Custom(ref err) => err,
        }
    }
}
```

`fmt::Display` is more flexible:

```rs
impl fmt::Display for MyErrorType {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match *self {
            MyErrorType::Io(ref err) => err.fmt(f),
            MyErrorType::Git(ref err) => err.fmt(f),
            MyErrorType::Regular(ref err) => write!(f, "A regular error occurred {:?}", err),
            MyErrorType::Custom(ref err) => write!(f, "A custom error occurred {:?}", err),
        }
    }
}
```

## Step 3 - Implement 'From' for the external error types

This enables the `?` operator:

```rs
impl From<io::Error> for MyErrorType {
    fn from(err: io::Error) -> MyErrorType {
        MyErrorType::Io(err)
    }
}

impl From<git2::Error> for MyErrorType {
    fn from(err: git2::Error) -> MyErrorType {
        MyErrorType::Git(err)
    }
}
```

## Step 4 - Optional - Create a 'Result<T, E>' alias

```
pub type Result<T> = std::result::Result<T, MyErrorType>;
```

This does nothing other than simplify (some would say make more opaque)
your function signatures.

## Step 5 - Use it!

```rs
fn some_func() -> Result<usize> {
    // Possible this will generate a std::io::Error.
    let _f = std::fs::File::create("aa")?;

    // Possible this will generate a git2::Error.
    let _g = Repository::init("/path/to/a/repo")?;

    // Return one of my one errors.
    Err(MyErrorType::Regular(ErrorKind::NotAuthorized))
}
```
