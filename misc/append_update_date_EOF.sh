#!/usr/bin/env bash

# REGEX IS STILL THE MONARCHY
# Joe Schlimmer
# regex101.com saves my butt again

regexDate="[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}"

if ! tail -n1 README.md | grep -q "$regexDate"; then
    echo -e "\n$(date '+%Y-%m-%d')" >> README.md
else
    sed -i "$ s/"$regexDate"$/$(date '+%Y-%m-%d')/" README.md
fi
