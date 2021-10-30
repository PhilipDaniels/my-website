You need to install hugo separately

    $ sudo apt install hugo

The main website is cloned from https://github.com/PhilipDaniels/my-website
(of course).

A second repository https://github.com/PhilipDaniels/philipdaniels.github.io,
is configured as a git submodule (see git@github.com:PhilipDaniels/philipdaniels.github.io.git).

You must fetch this before beginning work

    $ git submodule init
    $ git submodule update

Once you have done that, use the `publish` script to build the website into the `public`
folder and push all the files to **both** git repos.

n.b. When I first did this I got into a detached HEAD state in the public folder.
A manual push of HEAD onto the master branch fixed it.
