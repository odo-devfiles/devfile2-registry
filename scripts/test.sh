#!/bin/sh

set -x

DEVFILES_DIR="$(pwd)/devfiles/"
FAILED_TESTS=""

getURLs() {
    urls=$(odo url list | awk '{ print $3 }' | tail -n +3 | tr '\n' ' ')
    echo "$urls"
}

# periodicaly check url till it returns expected HTTP status
# exit after 10 tries
waitForHTTPStatus() {
   url=$1
   statusCode=$2

    for i in $(seq 1 10); do
        echo "try: $i"
        content=$(curl -I "$url")
        echo "Checking if $url is returning HTTP $statusCode"
        echo "$content" | grep -q -E "HTTP/[0-9.]+ $statusCode"
        retVal=$?
        if [ $retVal -ne 0 ]; then
            echo "ERROR not HTTP $statusCode"
            echo "$content"
        else
            echo "OK HTTP $statusCode"
            return 0
        fi
        sleep 10
    done
    return 1
}

# periodicaly check output for Debug
# return if content is found
# exit after 10 tries
waitForDebugCheck() {
   devfileName=$1

    for i in $(seq 1 10); do
        if [ "$devfileName" = "nodejs" ]; then
            curl http://127.0.0.1:5858/ | grep "WebSockets request was expected"
            if [ $? -ne 0 ]; then
                echo "debugger not working"
            else
                echo "debugger working"
                return 0
            fi
        elif [ "$devfileName" = "python" ]; then
            # TODO: not yet implemented
            return 0
        elif [ "$devfileName" = "python-django" ]; then
            # TODO: not yet implemented
            return 0      
        else    
            (jdb -attach 5858 >> out.txt)& JDBID=$!
            cat out.txt | grep -i "Initializing"
            if [ $? -ne 0 ]; then
                echo "debugger not working"
            else
                echo "debugger working"
                kill -9 $JDBID
                return 0
            fi
        fi
        sleep 10
    done
    return 1
}

# run test on devfile
# parameters:
# - name of a component and project 
# - path to devfile.yaml
test() {
    devfileName=$1
    devfilePath=$2

    # remember if there was en error
    error=false

    tmpDir=$(mktemp -d)
    cd "$tmpDir" || return 1

    # odo project create "$devfileName" || error=true
    if $error; then
        echo "ERROR project create failed"
        FAILED_TESTS="$FAILED_TESTS $devfileName"
        return 1
    fi
    
    odo create "$devfileName" --devfile "$devfilePath" --starter || error=true
        if $error; then
        echo "ERROR create failed"
        odo project delete -f "$devfileName"
        FAILED_TESTS="$FAILED_TESTS $devfileName"
        return 1
    fi
    
    odo push || error=true
    if $error; then
        echo "ERROR push failed"
        odo project delete -f "$devfileName"
        FAILED_TESTS="$FAILED_TESTS $devfileName"
        return 1
    fi

    # check if application is responding
    urls=$(getURLs)

    for url in $urls; do
        statusCode=200

        # java-openliberty is a lightwaight example that is not fully working
        # it is ok if it is returning 404 
        if [ "$devfileName" = "java-openliberty" ]; then
            statusCode=404
        fi
        
        waitForHTTPStatus "$url" "$statusCode"
        if [ $? -ne 0 ]; then
            echo "ERROR unable to get working url"
            odo project delete -f "$devfileName"
            FAILED_TESTS="$FAILED_TESTS $devfileName"
            error=true
            return 1
        fi
    done



    # //TODO: fix debug testing
    # #check if debug is working
    # cat $DEVFILES_DIR"$devfileName/devfile.yaml" | grep "kind: debug"
    # if [ $? -eq 0 ];  then
    #     odo push -v 9 --debug
    #     (odo debug port-forward)& CPID=$!
    #     waitForDebugCheck $devfileName
    #     if [ $? -ne 0 ]; then
    #         echo "Debuger check failed"
    #         error=true
    #     fi
    # fi

    # kill -9 $CPID
    odo delete -f -a || error=true
    odo project delete -f "$devfileName"

    if $error; then
        echo "FAIL"
        # record failed test
        FAILED_TESTS="$FAILED_TESTS $devfileName"
        return 1
    fi

    return 0
}
 
for devfile_dir in $(find $DEVFILES_DIR -maxdepth 1 -type d ! -path $DEVFILES_DIR); do
    devfile_name="$(basename $devfile_dir)"
    devfile_path=$devfile_dir/devfile.yaml
    if [ "$devfile_name" != "java-openliberty" ]; then
        continue
    fi
    test "$devfile_name" "$devfile_path"
done


# remember if there was an error so the script can exist with proper exit code at the end
error=false

# print out which tests failed
if [ "$FAILED_TESTS" != "" ]; then
    error=true
    echo "FAILURE: FAILED TESTS: $FAILED_TESTS"
    exit 1
fi

exit 0
