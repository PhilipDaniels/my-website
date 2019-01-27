---
title: "File Management in the Terminal"
date: "2019-01-27"
draft: false
tags: [unix, command line]
---


# Copying files and directories

- [cp manual](http://man7.org/linux/man-pages/man1/cp.1.html) Duplicate an entire directory including subfolders `cp -r SRC DEST`
- Create a symbolic link to a file `cp -s FILE NEWLINK` (equivalent to `ln -s FILE NEWLINK`)
- Create a hard link to a file `cp -l FILE NEWLINK` (equivalent to `ln FILE NEWLINK`)

# Getting information

- [stat manual](http://man7.org/linux/man-pages/man1/stat.1.html) Print last access time, modify time etc. `stat FILE`
- [du manual](http://man7.org/linux/man-pages/man1/du.1.html)Show summary size of a directory in human language `du -sh DIR`
  - Exclude certain files `--exclude=’*.o’` (pattern is a shell pattern)
- [find manual](http://man7.org/linux/man-pages/man1/find.1.html) Count files in a directory `find DIR -type f | wc -l` (or use ncdu)

# Looking in files

- [cat manual](http://man7.org/linux/man-pages/man1/cat.1.html) Number the lines in a file `cat -n FILE`
  - [nl manual](http://man7.org/linux/man-pages/man1/nl.1.html) A more sophisticated version of the above `nl file`
- [head manual](http://man7.org/linux/man-pages/man1/head.1.html) Show first N lines of a file `head -3 FILE`
- [tail manual](http://man7.org/linux/man-pages/man1/tail.1.html) Show last N lines of a file `tail -3 FILE`
- Follow modifications to a file and finish when the process terminates `tail –pid=PID -f FILE`

# Manage permissions and owners

- [chmod manual](http://man7.org/linux/man-pages/man1/chmod.1.html) Change permissions of a file `chmod`
- [chown manual](http://man7.org/linux/man-pages/man1/chown.1.html) Change the owner of a file `chown`
- [chgrp manual](http://man7.org/linux/man-pages/man1/chgrp.1.html) Change the group owner of a file `chgrp`

# Misc

- [xdg-open manual](https://linux.die.net/man/1/xdg-open) Open any file from the command line in its associated program `xdg-open FILE`
