---
title: "File Sharing Between Linux and Windows"
date: "2019-01-27"
draft: false
tags: [linux, windows, samba, smbfs, share]
---

# Creating a Samba Share on Linux

Edit `/etc/samba/smb.conf` adding a stanza at the bottom something like this (`[slow]` is the name the share
will have). Notice the valid users.

```
[slow]
	path = /home/phil/slow
	available = yes
	valid users = phil
	read only = no
	browsable = yes
	public = yes
	writable = yes
```

Then do `sudo smbpasswd -a USER` and enter a Samba password for the user, then restart Samba
`sudo service smbd restart`. The share should now be mappable in Windows as `\\plato\slow`, use a
username of `phil` (no prefixes such as plato\phil) and the relevant password.

You might have to adjust Security Policy on Windows 10 to be able to map the share. Do `run secpol`
and navigate to `Local Policies → Security Options -> Network Security: LAN Manager authentication level`.
I set it to `Send NTMLv2 response only`, but that was while trying to connect to an improperly
setup share. It might not actually be necessary.

# Permanently Mount a Windows Share in Linux Mint

See [https://wiki.ubuntu.com/MountWindowsSharesPermanently](https://wiki.ubuntu.com/MountWindowsSharesPermanently).
I added these lines to `/etc/fstab`:

```
//192.168.0.202/data /home/phil/win-data cifs credentials=/home/phil/.smbcredentials,uid=1000,gid=1000,iocharset=utf8,sec=ntlm,vers=1.0,rw 0 0
//192.168.0.202/backup /home/phil/win-backup cifs credentials=/home/phil/.smbcredentials,uid=1000,gid=1000,iocharset=utf8,sec=ntlm,vers=1.0,rw 0 0
```

And `~/.smbcredentials` just contained:

```
username=phil
password=the usual
```

# Temporarily Access a Windows Share from Linux

In Nemo, do **File → Connect to server** then enter

```
Server = NAMMEOFWINDOWSMACHINE
  Share = r
  Folder = /
  Domain Name = blank usually works (or maybe WORKGROUP)
  User = phil
  Password = THE USUAL
```

You may also need to edit `/etc/nsswitch.conf` to add this line (the wins is the important bit):

    hosts: files wins dns
