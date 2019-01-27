---
title: "Installing LibreOffice with Python Scripting Support"
date: "2019-01-27"
draft: false
tags: [linux, office, libreoffice, python]
---

See

- [https://ask.libreoffice.org/en/question/154007/how-to-upgrade-libreoffice-version-using-linux-mint/](https://ask.libreoffice.org/en/question/154007/how-to-upgrade-libreoffice-version-using-linux-mint/)
- [https://askubuntu.com/questions/132837/how-do-i-install-the-latest-stable-version-of-libreoffice](https://askubuntu.com/questions/132837/how-do-i-install-the-latest-stable-version-of-libreoffice)
- And for python: [https://ask.libreoffice.org/en/question/140787/where-does-libreoffice-expect-user-scripts-pythonjavajavascript-to-be-located-on-ubuntu/](https://ask.libreoffice.org/en/question/140787/where-does-libreoffice-expect-user-scripts-pythonjavajavascript-to-be-located-on-ubuntu/)

Basically I just did:

```
sudo add-apt-repository ppa:libreoffice/ppa
sudo apt-get update
sudo apt-get upgrade # Should try dist-upgrade instead
sudo apt install libreoffice # Needed to bring down the latest version
sudo apt install libreoffice-script-provider-python
```
