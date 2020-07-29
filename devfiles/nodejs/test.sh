#!/bin/sh

set -e

odo preference set Experimental true
odo project create test -w
odo create nodejs --devfile https://raw.githubusercontent.com/openshift/odo/master/tests/examples/source/devfiles/nodejs/devfile.yaml
