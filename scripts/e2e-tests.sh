#!/bin/sh

set -e

odo preference set Experimental true
odo project create test -w
odo create nodejs --devfile devfiles/nodejs/devfile.yaml
odo push
