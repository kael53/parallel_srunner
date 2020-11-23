#!/bin/bash
[ -z "$1" ] && echo "usage ./run_autopilot.sh port_number" && exit 1
screen -dm -L -S carla-autopilot-$1 python3 autopilot.py --port $1 --tm-port $(($1+60))


