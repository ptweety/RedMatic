#!/bin/bash

BUILD_DIR=`cd ${0%/*} && pwd -P`

if [ -z "$GITHUB_RUN_ID" ]; then
    echo "skipping wiki CHANGE_HISTORY.md update..."
    exit 0
fi

echo "updating wiki CHANGE_HISTORY.md..."
git clone https://github.com/ptweety/RedMatic.wiki
node update_change_history.js > RedMatic.wiki/CHANGE_HISTORY.md
cd RedMatic.wiki

if [ $GITHUB_RUN_ID ]; then
    git remote add wiki-push https://${GITHUB_OAUTH_TOKEN}@github.com/ptweety/RedMatic.wiki > /dev/null 2>&1
    git commit -m "Update CHANGE_HISTORY.md ([Github Action $GITHUB_WORKFLOW #$GITHUB_RUN_NUMBER](https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID))" CHANGE_HISTORY.md
    git push wiki-push master
fi

cd $BUILD_DIR
rm -rf RedMatic.wiki