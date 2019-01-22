---
title: "Setup of Debian Virtual Machines"
date: 2016-12-27T20:19:45Z
draft: false
tags: [linux, vm, debian]
---

## Other Build Book Posts

* [Setup of SSH]({{< ref "setup-of-ssh.md" >}})
* [Windows VM Setup]({{< ref "windows-vm-setup.md" >}})
* [Network Setup in Hyper-V and Virtual Box]({{< ref "vm-networking-overview.md" >}})

Posts in the Build Book sequence are intended primarily as an aide-mémoire for
myself; a series of steps to go through for a consistent build experience. They
tend to be to the point, prescriptive and tailored for me personally.

## Installation Steps

Pick the
[type of Debian distribution](https://www.debian.org/doc/manuals/debian-faq/ch-choosing.en.html)
you want. I usually go for Testing to keep up with the latest fixes - it is a
rolling release. Download a Testing netinst image for amd64 (for 64bit VMs) from
https://www.debian.org/devel/debian-installer/.

* Create a VM and add a network card. 1GB of RAM and 128GB of disk are OK.
  Adjust CPUs to taste.
* Do a graphical install.
* If you are installing a machine with more than one network interface, you will
  be asked to pick the primary one. Pick the first, as this should be the NAT one.
* Hostname can be something simple, such as "deb2".
* Domain name can be "debnet".
* **DO NOT** set a root password. By omitting it you force Debian to install
  sudo. By default sudo is not installed and is a pain to add later, this trick
  makes for an easier life.
* New user: "Philip Daniels" for the full name, pick one word for the UID.
* Partition: Guided, use entire disk. All files in one partition.
* Configuring Package Manager proxy: this can be left blank at home. At work,
  the corporate proxy should authenticate you, but if it doesn't the precise magic
  to enter is in my password vault. See
  [Network Setup in Hyper-V and Virtual Box]({{< ref "vm-networking-overview.md" >}})
* Software selection: typically I just go for "SSH Server" and "standard system
  utilities". It helps to keep the size down and everything else can be
  installed later with apt-get anyway.
* Install Grub, pick /dev/sda.
* Done.

## Post-Installation Setup

### Assign a Static IP

If at home, reserve a static IP on the router. At work, or to do it manually,
edit `/etc/network/interfaces`. See `man interfaces` for more info or browse the
[Debian Network Configuration Guide](https://wiki.debian.org/NetworkConfiguration).

Something like this is typically seen for a machine with a DHCP configured
interface:

    # The primary network interface
    allow-hotplug eth0
    iface eth0 inet dhcp

The equivalent for a static IP is:

    auto eth0
    iface eth0 inet static
        address 192.0.2.7
        netmask 255.255.255.0
        gateway 192.0.2.254         # Get this from route -n

At work, if using the standard Virtual Box setup described in
[Network Setup in Hyper-V and Virtual Box]({{< ref "vm-networking-overview.md" >}}),
then the stanza for the second NIC will look something like:

    auto enp0s8
    iface enp0s8 inet static
        address 192.168.56.101
        netmask 255.255.255.0
        network 192.168.56.0
        broadcast 192.168.56.255


### Edit /etc/hosts

See [here]({{< ref "vm-networking-overview.md#simple-edit-the-hosts-file" >}}).

### Manual DNS Setup

If you have at least one interface setup by DHCP then DNS servers should be
discovered automatically. If you do not, or you want to override them, they are
specified in `/etc/resolv.conf`. Typically it looks like this:

    nameserver 192.168.0.1

You can add as many lines as you want. Google has publicly available nameservers
at `8.8.8.8` and `8.8.8.4`.

### Install my ssh key and setup forwarding

[See my post on SSH]({{< ref "setup-of-ssh.md#enabling-SSH-up-to-a-server" >}}).

### Setup dotfiles

    mkdir -p ~/repos && cd ~/repos
    sudo apt-get install git
    git clone git@github.com:PhilipDaniels/dotfiles
    cd dotfiles
    ./00install_dotfiles.sh
    ./10install_linux_cli.sh

## Getting files into and out of Debian VMs

### Using FileZilla

For one-off file transfers, this is the easiest way. Basically, just setup SSH
on Windows and connect using FileZilla. Drag and drop files. See [SSH Setup]({{<
ref "setup-of-ssh.md#using-ssh-with-windows-apps" >}}) for precise
details.

### Sharing with Samba

[This guide](http://www.howtogeek.com/176471/how-to-share-files-between-windows-and-linux/)
is the best I have seen. Covers accessing a Windows share from Linux, and
creating a share in Linux which can be accessed from Windows.

One thing to bear in mind when accessing a Windows share - you need to pick
and/or create a Windows user. Options:

1. Your day-to-day user. **Pros:** It will probably have the right permissions.
   **Cons:** The user must have a password for this to work, not all Windows
   users do. Also, if the password has to change then you will lose your mounts
   whenever the pwd changes.

2. A new user, such as “unix”. **Cons:** Even making it an Administrator won't
   give it full control over everything. For example, it will not be able to see
   into your day-to-day user's home folder.

The following commands may be useful for debugging purposes:

    # Browse shares, n.b. there is no "Phil" account on hyperbox.
    smbclient -L hyperbox -W workgroup -U hyperbox\\userid

    sudo mount -t cifs //hyperbox/d ./hd -o username=userid,password=pwd,domain=hyperbox

    # Puts you in a shell, you can do “ls”, “cd” etc. Good for checking.
    smbclient \\\\hyperbox\\d -U hyperbox\\userid pwd

See also https://forums.gentoo.org/viewtopic-t-926114.html and
https://debian-handbook.info/browse/stable/sect.windows-file-server-with-samba.html

### Permanent Mounting with /etc/fstab

Create a directory(s) to serve as the mount point:

    cd /mnt
    sudo mkdir c r s t

Add the following lines to `/etc/fstab` (where hyperbox is the Windows server):

    # You may use spaces to separate fields. See "man fstab" for details of what each field is, and
    # "man mount" and "man mount.cifs" for details of the options, but auto means can be mounted with
    # "mount -a", not that it is mounted automatically at boot time (they *all* are if they are in
    # this file). The "comment=" is necessary to get the mounts to work at boot time (this is known to
    # work on Debian Stretch as of July 2016).
    //hyperbox/c$ /mnt/c cifs credentials=/home/phil/.smbcredentials,iocharset=utf8,rw,noperm,nounix,auto,comment=systemd.automount
    //hyperbox/r$ /mnt/r cifs credentials=/home/phil/.smbcredentials,iocharset=utf8,rw,noperm,nounix,auto,comment=systemd.automount
    //hyperbox/s$ /mnt/s cifs credentials=/home/phil/.smbcredentials,iocharset=utf8,rw,noperm,nounix,auto,comment=systemd.automount
    //hyperbox/t$ /mnt/t cifs credentials=/home/phil/.smbcredentials,iocharset=utf8,rw,noperm,nounix,auto,comment=systemd.automount


Create a file `/home/phil/.smbcredentials` (actually it can be anywhere) to hold
your user id and password. Add the following lines (note no spaces):

    domain=hyperbox
    username=user
    password=password

And secure it:

    chmod 600 /home/phil/.smbcredentials

Then refresh mount points:

    sudo mount -a

If you make a mistake, to unmount something do:

    sudo umount /mnt/c

More info at https://wiki.ubuntu.com/MountWindowsSharesPermanently and
https://wiki.centos.org/TipsAndTricks/WindowsShares (which also includes a
discussion of auto-mounting shares as and when needed).
