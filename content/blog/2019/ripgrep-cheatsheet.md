---
title: "Ripgrep Cheatsheet"
date: "2019-04-14"
draft: false
tags: [unix, ripgrep]
---

# Ripgrep

| Syntax | Description
| ------ | -----------
| <code>rg --help &#124; more</code> | Make help useful on Windows
| `rg -l NEEDLE` | List matching files only
| `rg -c NEEDLE` | List matching files, including a count
| `rg -i NEEDLE` | Search case-insensitively
| `rg --no-filename NEEDLE` | Don't print filenames, handy when you care about the match more than the file
| `rg -v NEEDLE` | Invert matching: show lines that do not match
| `rg NEEDLE README.md` | Search only in specified file(s)
| <code>rg -c &hyphen;&hyphen;sort path&#124;modified&#124;accessed&#124;created NEEDLE<code> | Sort the results (`-sortr` to reverse)
| `rg -g '*.nuspec' NEEDLE` | Only search in `*.nuspec` files (can use multiple `-g`)
| `rg -g '!*.nuspec' NEEDLE` | Search in everything but `*.nuspec` files
| <code>rg -p NEEDLE &#124; less -R</code> | Force pretty printed output even in pipes
| `rg -e NEEDLE1 -e NEEDLE2` | Search for multiple patterns
| `rg -z NEEDLE` | Search in gzip, bzip2, xz, LZ4, LZMA, Brotli and Zstd compressed files
| `rg --type-list` | Displays built-in available types and their corresponding globs
| `rg -tcs -tconfig` | Search in file types `cs` and `config`
| `rg -Tconfig` | **Don't** search in file type `config`

**Note 1** If `NEEDLE` or `-g` patterns contain any special characters then place them in **single**
quotes. Double quotes will work in some circumstances, but negative `-g` patterns in double
quotes seem to confuse the shell, on Linux at least.

**Note 2** Remember that `NEEDLE` is a Regex, hence characters such as `.` (dot) have special meaning
even when placed in single quotes. To match a literal `.` you need to use a Regex-escape: `\.`

## PowerShell

On Windows, you can pipe results to PowerShell like this:

```bash
rg -i --no-filename '<PackageReference' | foreach { $_.Trim() } | Sort-Object -unique
```

## Links

[Ripgrep repository](https://github.com/BurntSushi/ripgrep)

[User guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)

[Regex syntax Guide](https://docs.rs/regex/1/regex/#syntax)
