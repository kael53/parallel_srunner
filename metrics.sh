#!/bin/bash
[ -z "$1" ] || [ -z "$2" ] && echo "usage ./metrics.sh path/to/logfile.log path/to/metrics.py" && exit 1

./run_carla.sh 2053

sleep 20

python3 $SCENARIO_RUNNER_ROOT/metrics_manager.py --port 2053 --log $(realpath --relative-to="$SCENARIO_RUNNER_ROOT" "$PWD/$1") --metric $2

screen -ls | grep carla-simulator-2053 | cut -d. -f1 | awk '{print $1}' | xargs kill &> /dev/null
