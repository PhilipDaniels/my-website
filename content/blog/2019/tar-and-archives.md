---
title: "The tar command and managing archives"
date: "2019-01-27"
draft: false
tags: [unix, command line, tar, archive]
---

# Compressing and archiving files
For dealing with directories it is normal to use the `tar` command, see below.

* `.bz2` extension is managed by the commands [bzip2](https://linux.die.net/man/1/bzip2), bzcat and bunzip2.
  * Deal with a single file `bzip2 FILE1 FILE2…`, `bzcat FILEs`, `bzunzip2 FILEs` (the file is replaced)
* `.gz` extension is managed by the commands [gzip](https://linux.die.net/man/1/gzip), zcat and gunzip.
  * Usage is the same as `bzip2`. It can also uncompress `.zip` files.
* `.zip` extension is managed by the commands [zip](https://linux.die.net/man/1/zip) and unzip.
  * Compress a directory `zip -r FILE.ZIP DIR`
  * Uncompress a zip, re-creating the recursive structure: `unzip FILE.ZIP`

# The tar command

- Create a tar archive `tar -cvf NEW.tar DIR1 DIR2 DIR3…`
- Create a tar archive and zip it in one step `tar -czvf NEW.tar.gz DIR1 DIR2 DIR3…`
- Create a tar archive and bzip2 it in one step `tar -cjvf NEW.tar.bz2 DIR1 DIR2 DIR3…`
- List the contents of a tar archive without extracting `tar -tf FILE.tar (works for compressed tars too)`
- Extract a tar archive into the current directory `tar -xvf FILE.tar`
- Extract a tar archive into another directory (that must exist) `tar -xvf FILE.tar -C DIR` (that is a capital C)
- Extract only a certain path `tar -xvf FILE.tar home/phil/Documents/Cacti` i.e. without a leading slash. The final path is the last thing on the command line.
