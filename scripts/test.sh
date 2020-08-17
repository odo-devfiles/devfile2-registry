#!/bin/sh

set -x

DEVFILES_DIR="$(pwd)/devfiles/"
FAILED_TESTS=""

# count how many tests were executed
executedTests=0

# return url of an odo url called "myurl"
getURL() {
    urlName=$1
    # get 3rd colum from second line
    url=$(odo url describe "$urlName" | odo url describe myurl | tail -n+2 | awk '{ print $3 }')
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
    exampleDir=$3
    urlPort=$4
    urlPath=$5
    checkString=$6

    # remember if there was en error
    error=false

    tmpDir=$(mktemp -d)
    cd "$tmpDir" || return 1

    git clone --depth 1 "$exampleRepo" .
    cd "${tmpDir}/${exampleDir}" || return 1

    odo project create "$devfileName"
    odo create "$devfileName" --devfile "$DEVFILES_DIR/$devfileName/devfile.yaml"
    odo url create myurl --port "$urlPort"
    odo push

    # check if appplication is returning expected content
    url=$(getURL "myurl")
    waitForContent "${url}${urlPath}" "$checkString"
    if [ $? -ne 0 ]; then
        echo "'$checkString' was not found"
        error=true
    fi

    odo log

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


# run odo in experimental mode
odo preference set -f experimental true


# run test scenarios
test "java-maven" "https://github.com/odo-devfiles/springboot-ex.git" "/" "8080" "/" "You are currently running a Spring server built for the IBM Cloud"
test "java-openliberty" "https://github.com/OpenLiberty/application-stack.git" "templates/default/" "9080" "/starter/" "Welcome to your Open Liberty Microservice built with Odo"
test "java-quarkus" "https://github.com/odo-devfiles/quarkus-ex" "/" "8080" "/" "Congratulations, you have created a new Quarkus application."
test "java-springboot" "https://github.com/odo-devfiles/springboot-ex.git" "/" "8080" "/" "You are currently running a Spring server built for the IBM Cloud"
test "nodejs" "https://github.com/odo-devfiles/nodejs-ex.git" "/" "3000" "/" "Hello from Node.js Starter Application!"

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

if [ "$error" == "true" ]; then
    exit 1
fi
exit 0
