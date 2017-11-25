#!/bin/bash

## You'll need to first install two packages:
##    brew install jq csvtomd

## NOTE: @ianyh says:
##    https://github.com/ianyh/Amethyst/issues/317#issuecomment-207152749
##      > I'm not entirely sure what to do about dotfiles. I kind of want to phase them out.

config=${1:-default.amethyst}
tmpfile=$(mktemp)
echo '"modifier","key","action"' > $tmpfile
cat $config | jq -r '.|to_entries | map(select(.value.key?)) | .[] | [.value.mod,.value.key,.key] | @csv' >> $tmpfile
perl -i -pe 's/mod1/^ ⇧ ⌘/; s/mod2/^ ⇧ ⌘ ⌥/' $tmpfile
csvtomd $tmpfile | tee keys.md
rm -f $tmpfile
cat $config | jq '{mod1:.mod1,mod2:.mod2}'
