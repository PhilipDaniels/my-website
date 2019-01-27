---
title: "Linux User Management"
date: "2019-01-27"
draft: false
tags: [linux, unix, command line, users]
---

- [useradd manual](http://man7.org/linux/man-pages/man8/useradd.8.html)
- [userdel manual](http://man7.org/linux/man-pages/man8/userdel.8.html)
- [usermod manual](http://man7.org/linux/man-pages/man8/usermod.8.html)
- [passwd manual](http://man7.org/linux/man-pages/man1/passwd.1.html)
- [groupadd manual](http://man7.org/linux/man-pages/man8/groupadd.8.html)
- [groupdel manual](http://man7.org/linux/man-pages/man8/groupdel.8.html)
- [groups manual](http://man7.org/linux/man-pages/man1/groups.1.html)
- [sudo manual](https://linux.die.net/man/8/sudo)
- [su manual](http://man7.org/linux/man-pages/man1/su.1.html)

- List all users `cat /etc/passwd` It’s the first column. Or `awk -F : ‘{print $1, “uid=”$3, “gid=”$3}’ /etc/passwd`
- List the default settings for adding a new user `useradd -D` The shell will often be just `/bin/sh`, which is not what you want
- Add a new user `sudo useradd -c “Joe Bloggs” -m -s “/bin/bash” jbloggs` then `sudo passwd jbloggs` to set his password. If you set it to something simple, then use `sudo passwd -e USER` they will have to change their password on first login.
- Login as another user `su jbloggs`
- Delete a user, including their home directory `sudo userdel -r USER`. The command `deluser` can remove all files owned by the user as well.
- Lock and unlock an account `sudo usermod -L USER` and `sudo usermod -U USER`
- Set an account to expire on a date `sudo usermod -e 2018-08-14`
- Create and delete groups `sudo groupadd GROUP` and `sudo groupdel GROUP`
- Add a user into some more groups `sudo usermod -a -G ADDITIONALGROUPs USER`
- Specify **exactly** the groups a user is a member of `sudo usermod -G GROUP1,GROUP2,GROUPN USER`. If the user is a member of a group not specified then they will be removed from that group.
- Remove a user from a group `sudo deluser USER GROUP`
- Enable a user to do sudo `usermod -a -G sudo USER`
- List groups a user is a member of `groups USER` or just `groups` for your own account. To see the numerical Ids as well, do `id USER`.
