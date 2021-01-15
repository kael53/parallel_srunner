#!/bin/bash
[ -z "$1" ] || [ -z "$2" ] && echo "usage ./metrics.sh path/to/logfile.log path/to/metrics.py" && exit 1

test_connection() {
if ( nc -zv localhost $1 &> /dev/null );
        then return 0;
        else return 1;
fi
}

run_carla() {
if ! test_connection $1 && ! test_connection $(($1+1)); then
SDL_VIDEODRIVER=offscreen screen -dm -L -S carla-simulator-$1 bash $CARLA_ROOT/CarlaUE4.sh -carla-world-port=$1 -opengl -benchmark -fps=20
return 0;
else echo "port $1 or $(($1+1)) is unavailable" && return 1;
fi
}

ret_str=$(run_carla 2000)
ret_num=$?
if [ "$ret_num" -eq "1" ]; then echo "error: $ret_num" && exit 1; fi

sleep 15

python3 $SCENARIO_RUNNER_ROOT/metrics_manager.py --log $(realpath --relative-to="$SCENARIO_RUNNER_ROOT" "$PWD/$1") --metric $2

screen -ls | grep carla-simulator-2000 | cut -d. -f1 | awk '{print $1}' | xargs kill &> /dev/null
