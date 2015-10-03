#!/bin/sh

APP_NAME="$1"
BUNDLE_PREFIX="$2"
CreateAppOnPortal.rb "$APP_NAME" $BUNDLE_PREFIX

gym -s PublishingTestApp -e "$APP_NAME Development.mobileprovision" -i "iPhone Developer: Pavel Yankelevich (UCERH6TMLJ)";