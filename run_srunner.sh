#!/bin/bash
[ -z "$1" ] || [ -z "$2" ] && echo "usage ./run_srunner.sh port_number scenario" && exit 1
screen -dm -L -S carla-srunner-$1 python3 $SCENARIO_RUNNER_ROOT/scenario_runner.py --scenario $2 --reloadWorld --record $(realpath --relative-to="$SCENARIO_RUNNER_ROOT" "$PWD") --output --port $1 --trafficManagerPort $(($1+60))

