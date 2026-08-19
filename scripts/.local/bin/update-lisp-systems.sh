#!/bin/bash

# set -x

export LISPDIR=~/SourceCode/lisp

cd "$LISPDIR" || exit
for dir in "$LISPDIR"/*; do
    if [[ -d $dir/.git ]]; then
        # echo "Tracking remote branches ..."
        # for remote in `git branch -r`
        # do
        #     git branch --track ${remote#origin/} $remote
        # done
        
        echo "Updating $dir"
        cd "$dir" || exit &&

                DEFAULT_BRANCH=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')

        echo "THE DEFAULT BRANCH IS: $DEFAULT_BRANCH"

        git checkout "$DEFAULT_BRANCH" && 
            git fetch --all && 
            git pull --all

        cd "$LISPDIR" || exit
        echo '[Done.]'
    fi
done
