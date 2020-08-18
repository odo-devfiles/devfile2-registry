#!/bin/bash

# fail if some commands fails
#set -e
# show commands
set -x

pushd devfiles

for dir in `ls -d */`; do
    echo "--------Validating devfile in $dir--------"
    TMP_DIR=$(mktemp -d)
    export GLOBALODOCONFIG=$TMP_DIR/preference.yaml
    odo preference set Experimental true
    echo "$dir"
    COMP_NAME=`echo $dir | sed 's:/*$::'`
    PROJECT_NAME=`LC_CTYPE=C tr -dc a-z < /dev/urandom | head -c 10 | xargs`
    URL=`LC_CTYPE=C tr -dc a-z < /dev/urandom | head -c 5 | xargs`
    echo "$URL"
    HOST=`LC_CTYPE=C tr -dc a-z < /dev/urandom | head -c 5 | xargs`
    echo "$HOST"
    PORT=`cat $COMP_NAME/devfile.yaml | grep targetPort | awk '{split($0,a,":"); print a[2]}' | sed -e 's/^[[:space:]]*//'`
    echo "$PORT"
    odo project create $PROJECT_NAME -w
    odo create $COMP_NAME --devfile $COMP_NAME/devfile.yaml --project $PROJECT_NAME --context $TMP_DIR
    # https://github.com/openshift/odo/issues/3767
    # odo url create $URL --port $PORT --host $HOST.com --context $TMP_DIR --ingress
    pushd $TMP_DIR
    odo url create $URL --port $PORT --host $HOST.com --ingress
    popd
    odo push --context $TMP_DIR
    if [[ $? -ne 0 ]]; then
        echo "May be add sample projects"
    fi
    odo project delete $PROJECT_NAME -f
    rm -rf $TMP_DIR
    echo "--------End of validation of devfile in $dir--------"
done

popd
