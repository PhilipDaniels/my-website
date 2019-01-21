#!/bin/bash

# Based on https://gohugo.io/hosting-and-deployment/hosting-on-github/

if pgrep hugo >/dev/null 2>&1
then
    echo -e "\033[0;31mHugo is running! Stop it first.\033[0m"
    exit 1
fi

echo -e "\033[0;32mBuilding site...\033[0m"
hugo

# Commit the contents of the public folder in preparation
# for pushing it to its own remote
#   git@github.com:PhilipDaniels/philipdaniels.github.io.git
cd public
git add .
msg="Rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"


echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
git push origin master

cd ..

echo -e "\033[0;32mAll done.\033[0m"