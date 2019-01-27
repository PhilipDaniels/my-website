---
title: "Process Management in the Terminal"
date: "2019-01-27"
draft: false
tags: [unix, command line]
---

# Signals

The recommended [signals](https://en.wikipedia.org/wiki/Signal_(IPC)) to stop a program, in increasing severity, are **TERM (15), INT (2), HUP (1), KILL (9)**

The [kill](http://man7.org/linux/man-pages/man1/kill.1.html) command is used to send signals to a program.

* Send a specific signal to a process: `kill -INT PID` or `kill -2 PID`
* The same to several processes: `kill -2 PID1 PID2 PID3`

* Killing processes by name

[kill processes](http://man7.org/linux/man-pages/man1/killall.1.html) processes by name `killall http*`
