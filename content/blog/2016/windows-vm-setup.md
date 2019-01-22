---
title: "Setup of Windows Virtual Machines"
date: 2016-12-27T20:14:13Z
draft: false
tags: [windows, vm]
---

## Other Build Book Posts

* [Debian VM Setup]({{< ref "debian-vm-setup.md" >}})
* [Setup of SSH]({{< ref "setup-of-ssh.md" >}})
* [Network Setup in Hyper-V and Virtual Box]({{< ref "vm-networking-overview.md" >}})

Posts in the Build Book sequence are intended primarily as an aide-mémoire for
myself; a series of steps to go through for a consistent build experience. They
tend to be to the point, prescriptive and tailored for me personally.

## General

* Do not use Windows Enterprise because this edition does not get patched and
  upgraded like normal Windows does.
* To enable Remote Desktop, you need to go into Control Panel in the VM and
  enable Remote Desktop. Remote Assistance can be disabled.
* When using RDP to connect to a VM to specify no domain, enter the user name as
  "\phil".
* Create a HOME environment variable at `C:\Users\phil` or similar. Cygwin will
  use this as your home directory.

## Install Cygwin, dotfiles and Chocolatey apps

We need to install Cygwin first in order to get Git. Run this from an elevated
command prompt (not ConEmu) to install all my Cygwin tools:

    @powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/philipdaniels/dotfiles/master/setup_cygwin.ps1'))"

Then create a directory ~/repos and install my dotfiles:

    git clone git@github.com:PhilipDaniels/dotfiles.git
    cd dotfiles
    ./00install_dotfiles.sh

See Emacs\EditWith.reg and the script in the PowerShell folder to install Visual
Studio snippets.

From an elevated command prompt

    ./setup_choco.ps1

This will install chocolatey itself, and a large list of programs. To upgrade
all chocolatey apps, do

    choco upgrade all -y

Chocolatey installs most apps into Program Files normally, but a large
proportion are put in `C:\ProgramData\chocolatey\bin`. This folder should get
added to your path, but if it isn't use the PathEditor.exe program to do so.


## Optional Post-Installation Steps

* **Profile** is at: `%UserProfile%\AppData\Roaming\Microsoft\Windows`. Open
  your Windows Start Menu folder and create shortcuts to the apps that you will
  be using frequently. This makes them available by searching by pressing the
  "Win" key.
* **PATH** The chocolatey setup installs a utility called `PathEditor.exe` which you can
  use to adjust the path. It is in the bin folder mentioned above.
* **Fonts** Download fonts from https://github.com/chrissimpkins/codeface and
  install them all (search for ttf in the unzipped folder).

## Commands for Debugging TCP in Windows

    nbtstat -n
    route print
    route delete 0.0.0.0
    ipconfig /release
    ipconfig /renew
    ipconfig /flushdns

To reset TCP/IP :
http://support.microsoft.com/kb/299357 http://www.timdavis.com.au/general/windows-7-default-gateway-0-0-0-0-problem/

    netsh int ip reset c:\resetlog.txt
    netsh winsock reset  c:\winsock.txt

Then reboot.

Check if these services are started and set to automatic.

    DHCP Client
    DNS Client
    Remote Procedure Call (RPC)
    TCP/IP Netbios helper
