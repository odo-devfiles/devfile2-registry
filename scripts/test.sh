#!/bin/sh

set -x

DEVFILES_DIR="$(pwd)/devfiles/"
FAILED_TESTS=""

# count how many tests were executed
executedTests=0

# return url of an odo url called "myurl"
getURL() {
    urlName=$1
    # get 3rd column from last line
    url=$(odo url list | grep ${urlName} | tail -1 | awk '{ print $3 }')
    echo "$url"
}

# periodicaly check url for content
# return if content is found
# exit after 10 tries
waitForContent() {
   url=$1
   checkString=$2

    for i in $(seq 1 10); do
        echo "try: $i"
        content=$(curl "$url")
        echo "$content" | grep -q "$checkString"
        retVal=$?
        if [ $retVal -ne 0 ]; then
            echo "content not found on url"
        else
            echo "content found on url"
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
#  - name of a devfile (directory in devfile registry)
#  - git url to example application
#  - directory within example repository where sample application is located (usually "/")
#  - port number for which url will be created
#  - url path to check for response (usually "/")
#  - string that url response must contain to checking that application is running corect 
test() {
    devfileName=$1
    exampleRepo=$2
    urlPort=$3
    urlPath=$4
    checkString=$5

    # remember if there was en error
    error=false

    tmpDir=$(mktemp -d)
    cd "$tmpDir" || return 1

    git clone --depth 1 "$exampleRepo" .

    # examples used in tests might contain Devfile.yaml
    # in this case it would break the test
    rm -rf devfile.yaml devfile.yml

    odo project create "$devfileName" || error=true
    odo create "$devfileName" --devfile "$DEVFILES_DIR/$devfileName/devfile.yaml" || error=true
    odo url create myurl --port "$urlPort" || error=true
    odo push || error=true

    # check if appplication is returning expected content
    url=$(getURL "myurl")
    waitForContent "${url}${urlPath}" "$checkString"
    if [ $? -ne 0 ]; then
        echo "'$checkString' was not found"
        error=true
    fi

    #check if debug is working
    cat $DEVFILES_DIR"$devfileName/devfile.yaml" | grep "kind: debug"
    if [ $? -eq 0 ];  then
        odo push --debug
        (odo debug port-forward)& CPID=$!
        waitForDebugCheck $devfileName
        if [ $? -ne 0 ]; then
            echo "Debuger check failed"
            error=true
        fi
    fi

    kill -9 $CPID
    odo delete -f -a
    odo project delete -f "$devfileName"

    executedTests=$((executedTests+1))
    if $error; then
        echo "FAIL"
        # record failed test
        FAILED_TESTS="$FAILED_TESTS $devfileName"
        return 1
    fi

    return 0
}
 

# run test scenarios
# parameters:
#  - name of a devfile (directory in devfile registry)
#  - git url of an example application
#  - port number for which url will be created
#  - url path to check for response (usually "/")
#  - string that url response must contain to checking that application is running corect 
test "java-maven" "https://github.com/odo-devfiles/springboot-ex.git" "8080" "/" "You are currently running a Spring server built for the IBM Cloud"
test "java-openliberty" "https://github.com/OpenLiberty/application-stack-intro.git" "9080" "/api/resource" "Hello! Welcome to Open Liberty"
test "java-quarkus" "https://github.com/odo-devfiles/quarkus-ex" "8080" "/" "Congratulations, you have created a new Quarkus application."
test "java-springboot" "https://github.com/odo-devfiles/springboot-ex.git" "8080" "/" "You are currently running a Spring server built for the IBM Cloud"
test "nodejs" "https://github.com/odo-devfiles/nodejs-ex.git" "3000" "/" "Hello from Node.js Starter Application!"
test "python" "https://github.com/odo-devfiles/python-ex.git" "8080" "/" "Hello World!"
test "python-django" "https://github.com/odo-devfiles/python-django-ex.git" "8000" "/" "The install worked successfully! Congratulations!"
test "java-vertx" "https://github.com/jponge/vertx-ex" "8080" "/" "Hello from Vert.x"


# remember if there was an error so the script can exist with proper exit code at the end
error=false

# print out which tests failed
if [ "$FAILED_TESTS" != "" ]; then
    error=true
    echo "FAILURE: FAILED TESTS: $FAILED_TESTS"
fi

# Check if we executed tests for every devfile
# TODO: check that every devfile was actually tested (based on directory name), not just number of tests executed
numberOfDevfiles=$(find $DEVFILES_DIR/*/devfile.yaml | wc -l)
if [ "$executedTests" -ne "$numberOfDevfiles" ]; then
    error=true
    echo "FAILURE: Not all devfiles were tested"
    echo "There is $numberOfDevfiles devfiles in registry but only $executedTests tests executed."
fi

if [ "$error" = "true" ]; then
    exit 1
fi
exit 0