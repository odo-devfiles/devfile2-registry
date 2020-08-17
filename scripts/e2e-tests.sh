#!/bin/sh

# fail if some commands fails
set -e
# show commands
set -x

cd devfiles

for dir in */; do
    if [ -d "$dir" ]; then
        TMP_DIR=$(mktemp -d)
        export GLOBALODOCONFIG=$TMP_DIR/preference.yaml
        odo preference set Experimental true
        echo "$dir"
        COMP_NAME=`echo $dir | sed 's:/*$::'`
        PROJECT_NAME=`LC_CTYPE=C tr -dc a-z < /dev/urandom | head -c 10 | xargs`
        odo project create $PROJECT_NAME -w
        odo create $COMP_NAME --devfile $COMP_NAME/devfile.yaml --context $TMP_DIR
        odo push --context $TMP_DIR
        rm -rf $TMP_DIR
    fi
done
