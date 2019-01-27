---
title: "Unix Redirections"
date: "2019-01-27"
draft: false
tags: [unix, command line, bash]
---

# Redirections

* Redirect stdout to a file: `> FILE`
* Append stdout to a file: `>> FILE`
* Redirect stderr to a file: `2> FILE`
* Redirect stdout and stderr to the same file by redirecting stream 2 to stream 1: `> FILE 2>&1`
  * Bash version of the above (non standard, avoid): `&> FILE` or `&>> FILE` for appending
* Redirect stdout and stderr to different files: `> FILE 2> ERRORFILE`
* Read stdin from a file: `< FILE`
* Read stdin from a file and write stdout to a file: `wc < input.txt > output.txt`
  * **CARE REQUIRED**: `command < FILE > FILE` might result in FILE getting clobbered due to the order of redirections

For more, see [IO Redirections](https://www.tldp.org/LDP/abs/html/io-redirection.html).
