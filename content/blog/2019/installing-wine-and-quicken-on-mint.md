---
title: "Installing Wine and Quicken 2000 on Linux Mint"
date: "2019-01-27"
draft: false
tags: [linux, quicken, wine]
---

# May need to install the latest Wine manually

You may first need to get the latest and greatest version of Wine. Mint 18 shipped with Wine 1.6
which was ancient, I am not sure which version Mint 19 ships with since I did an upgrade. In any
case, you can install the latest version of Wine by following [these steps]
(https://www.ubuntupit.com/install-winehq-ubuntu-linux-mint-instantly/)


```
sudo dpkg --add-architecture i386
wget -nc https://dl.winehq.org/wine-builds/Release.key
sudo apt-key add Release.key
sudo apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ xenial main'
sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install --install-recommends winehq-stable
```

Run winecfg to upgrade the config.

# Installing Quicken

Then copy the **Disks\Quicken** folder (the Quicken installation media) to somewhere on Linux,
and do `wine INSTALL.exe`. It should work, though there are some drawing issues. Then, you will
find Quicken installed to **~/.wine/drive_c/quickenw** You can copy an old installation from
Windows into this folder. When you run Quicken for the first time you will probably have to open
the data file manually.

If Quicken keeps nagging about Registration, go to **Online → One Step Update**. Some comments here http://blog.jdpfu.com/2010/11/29/solved-quicken-2011-working-on-linux
