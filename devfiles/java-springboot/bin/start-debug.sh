#!/bin/sh

# set -e -o pipefail

APP_JAR=/root/app.jar
TARGET_JAR=$(ls /data/output/*.jar | head -n1)

date
echo Started - Spring Server Script

# Kill the Spring App or Debug process if its running
date
echo Stopping the Spring App
pkill -f "java -jar $APP_JAR" || echo "No Java Spring Application process found"
pkill -f "java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=${DEBUG_PORT},suspend=n -jar $APP_JAR" || echo "No Java Debug process found"

# Copy the maven built jar from the PVC
date
echo Copying the maven built jar from the PVC
cp -rf $TARGET_JAR $APP_JAR

# Start the Spring Application
date
echo Starting the Spring Application
nohup java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=${DEBUG_PORT},suspend=n -jar $APP_JAR

date
echo Finished - Spring Server Script