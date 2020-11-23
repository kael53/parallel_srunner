#!/bin/bash
[ -z "$1" ] || [ -z "$2" ] && echo "usage ./clean.sh port scenarioname" && exit 1
rm $2.log $2.json screenlog-carla-simulator-$1 screenlog-carla-autopilot-$1 screenlog-carla-srunner-$1 screenlog-carla-carlaviz-$1
