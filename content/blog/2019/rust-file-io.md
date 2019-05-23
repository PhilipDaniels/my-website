---
title: "Rust File IO"
date: "2019-05-23"
draft: false
tags: [rust, file, io]
---

See [std::io](https://doc.rust-lang.org/std/io/index.html) for more details.

For dealing with the filesystem, such as opening or deleting files, see
[std::fs](https://doc.rust-lang.org/std/fs/index.html).

For manipulating paths, see
[std::path](https://doc.rust-lang.org/std/path/index.html).

For low-level network IO, see [std::net](https://doc.rust-lang.org/std/net/index.html).

# One Liners for Reading the Entire File

Use [read_to_string](https://doc.rust-lang.org/std/fs/fn.read_to_string.html)
and [read](https://doc.rust-lang.org/std/fs/fn.read.html).

These are both fast as they allocate a buffer of the required size to start with.

```rs
let contents: String = std::fs::read_to_string("/some/file")?;
let bytes: Vec<u8> = std::fs::read("/some/file")?;
```

# One Liners for Writing the Entire File

Use [write](https://doc.rust-lang.org/std/fs/fn.write.html).
The file will be created if it does not exist, replaced if it does.

The contents is anything that implements `AsRef<[u8]>` - which includes
[String](https://doc.rust-lang.org/std/string/struct.String.html)
and [str](https://doc.rust-lang.org/std/primitive.str.html).

```rs
let contents = "Some data!";
std::fs::write("/some/file", &data);
```

# Reading Files Line by Line

You should use [BufReader](https://doc.rust-lang.org/std/io/struct.BufReader.html)
to speed up reading. Note that you need to bring the
[BufRead](https://doc.rust-lang.org/std/io/trait.BufRead.html)
trait into scope to get access to the
[lines](https://doc.rust-lang.org/std/io/trait.BufRead.html#method.lines)
method.

```rs
use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() {
    let f = File::open("/some/file").unwrap();
    let f = BufReader::new(f);

    for line in f.lines() {
        let line = line.expect("Unable to read line");
        println!("{}", line);
    }
}
```

[Lines](https://doc.rust-lang.org/std/io/trait.BufRead.html#method.lines)
splits on LF (0xA) or CRLF (0xD,0xA). To split on other bytes, use
the [split](https://doc.rust-lang.org/std/io/trait.BufRead.html#method.split)
method.

# Getting All Lines From a File into a Vector

```rs
let lines = reader.lines().collect::<io::Result<Vec<String>>>()?;
```

# Writing

Writing is mainly done using macros, namely
[write!](https://doc.rust-lang.org/1.5.0/std/macro.write!.html)
and
[writeln!](https://doc.rust-lang.org/1.5.0/std/macro.writeln!.html).
See [fmt](https://doc.rust-lang.org/1.5.0/std/fmt/index.html)
for the juicy stuff.

If you're looking for functionality equivalent to C#'s
[TextWriter](https://docs.microsoft.com/en-us/dotnet/api/system.io.textwriter?view=netframework-4.8)
such as `Write(UInt32)`, this is how you do it, using the macros.


```rs
let f = File::open("/some/file").unwrap();
let f = BufWriter::new(f);
writeln!(f, "Hello {}, you are {} years old", name, age);
f.flush()?;
```

**VERY IMPORTANT**

Rigorous code should call [flush](https://doc.rust-lang.org/std/io/trait.Write.html#tymethod.flush)
explicitly rather than just letting Rust do it when the `BufWriter` is dropped. This is because
any errors from `flush` will be squashed inside `drop`. It is better to flush explicitly so
that errors are surfaced to the program.

Looking for the `BufWrite` trait to mirror [BufRead](https://doc.rust-lang.org/std/io/trait.BufRead.html)?
There is no such trait! Because there are no extra methods (over and above those on
[write](https://doc.rust-lang.org/std/fs/fn.write.html))
which `BufWrite` would add.


# Generic Code

It is typical to write code that is generic over `Read` and `Write` traits - or
`BufRead` and `BufWrite`. Note that the references are mutable.

```rs
fn copy<R,W>(reader: &mut R, writer: &mut W)
where
    R: Read,
    W: Write
{
    ...
}
```

# Stdin, Stdout and Stderr

Rust (and C also) guard reads and writes to the standard IO file descriptors
using a global lock. That lock will be obtained separately for every call to
[println!](https://doc.rust-lang.org/std/macro.println.html), for example.

To speed things up, you can obtain the lock once at the start of a writing
session and hold it until done.

The [lock](https://doc.rust-lang.org/std/io/struct.Stdout.html#method.lock) method
returns a [StdoutLock](https://doc.rust-lang.org/std/io/struct.StdoutLock.html)
which implements [Write](https://doc.rust-lang.org/std/io/trait.Write.html), so
you can use the `write!` and `writeln` macros with it.

```rs
use std::io::prelude::*;

fn main() {
    let stdout = std::io::stdout();
    let mut writer = stdout.lock();
    writeln!(writer, "Hello");
    writeln!(writer, " World");
    // lock released here
}
```

Same applies to
[stdin](https://doc.rust-lang.org/std/io/struct.Stdin.html)
and [stderr](https://doc.rust-lang.org/std/io/struct.Stderr.html)

