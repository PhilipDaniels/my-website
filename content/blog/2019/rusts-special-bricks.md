---
title: "[DRAFT] Rust's Special Bricks"
date: "2019-04-17"
draft: true
tags: []
---

# The Special Bricks

Rust is a data-oriented language. Can be seen in impl blocks which separate data
from code. Pays to think about data structures as 'tiling' memory with meaning.

A Rust data structure is an amalgamation of smaller parts that together build
a wall. By default, the wall cannot be changed.

Foreman is the borrow checker.
Contractors are the mutators.

There are certain special bricks that you can put in the wall to help things
out.

Box
Rc
Cell
RefCell
Arc
Mutex
RwLock
Atomic

Combinations of these

Dimensions:
single-threaded vs multi-threaded
interior mutability via runtime checking
single owner vs multiple owner
Send = safe to move it to another thread
Sync = safe to move &T to another thread






