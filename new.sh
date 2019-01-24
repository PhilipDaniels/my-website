#!/bin/bash

# We can create new "live" posts or new "draft"" posts.
what="$1"
case $what in
    "draft")
        draft=true
        ;;
    "live")
        draft=false
        ;;
    *)
        echo Usage: 'new draft' or 'new live'
        exit 1
esac


echo "
The post needs a shortname. It will form part of the URL.
It should be concise but clear, and use dashes instead of spaces.
Examples: ufw-intro, persistent-dictionary-vs-sqlite, emacs-theme-hydra.
"

read -p "  shortname > " shortname


year=`date +%Y`
month=`date +%m`

postdir=./content/blog/$year
imgdir=./content/blog/$year/$shortname
postfile=$postdir/$shortname.md


if [ -d $imgdir ]; then
    echo The image directory $imgdir already exists! Continuing...
fi
if [ -f $postfile ]; then
    echo The postfile $postfile already exists! Aborting.
    exit 1
fi

echo "
Now enter a longer, free-form human readable title. Spaces are fine.
Example: Running ConEmu inside Visual Studio
"

read -p "  title > " title


echo "
The post will be    : $what
         located at : $postfile
     with images at : $imgdir
     and long title : $title
"


read -p "Type y to proceed: " confirm
case $confirm in
    "y" | "Y")
        ;;
    *)
    echo Post not created.
    exit 0
esac


mkdir -p $imgdir
mkdir -p $postdir

cat <<EOF > $postfile
---
title: "$title"
date: "`date -I`"
draft: $draft
tags: []
---

# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5

Start your engines...

*This is italic* and **this is bold**, ***this is bold-italic*** and ~~this is strikethrough~~.

[A link](https://www.x.com)

![An image for this post](image1.png)

[Link to another post in this year]({{< ref "other-post.md" >}})
[Link to another post in another year]({{< ref "../2017/"other-post.md" >}})
[Link to a heading]({{< relref "#my-normalized-heading" >}}).

> This is a quote

Use 4 spaces to create pre-formatted text:

    $ some example text for example with <b> tags

A list is created using asterisks or dashes

* First
* Second
* Third

EOF

echo
echo "$postfile created."
