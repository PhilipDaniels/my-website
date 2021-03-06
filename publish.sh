#!/bin/bash

# Based on https://gohugo.io/hosting-and-deployment/hosting-on-github/

if pgrep hugo >/dev/null 2>&1
then
    echo -e "\033[0;31mHugo is running! Stop it first.\033[0m"
    exit 1
fi

# Remove everything except the CNAME file and the `.git` file which
# sets up the submodule.
echo -e "\033[0;32mCleaning out the public folder...\033[0m"
find public -type f -not -name 'CNAME' -not -name '.git' -delete

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

# Also commit the main website sources. Even if we committed all
# our changed files, the `hugo` step above will be showing changes
# in the `public` directory that are annoying.
echo -e "\033[0;32mCommitting website sources...\033[0m"
git add .
msg="Rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"
echo -e "\033[0;32mPushing website sources...\033[0m"
git push origin master


echo -e "\033[0;32mAll done.\033[0m"

