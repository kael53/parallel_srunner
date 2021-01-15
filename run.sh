#!/bin/bash
[ -z "$1" ] && echo "usage ./run.sh /path/to/instances.txt" && exit 1

load_map() {
map=$(grep "$2\"" scenario_runner/srunner/examples/FollowLeadingVehicle.xml | cut -f6 -d '"')
python3 -m util.config --map $map --port $1
}

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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

run_carlaviz() {
if ! test_connection $(($1+80)) && ! test_connection $(($1+81)); then
if python3 -m util.test_connection --port $1 --timeout 2; then
CARLAVIZ_HOST=localhost CARLAVIZ_PORT=$(($1+81)) CARLA_SERVER_IP=172.17.0.1 CARLA_SERVER_PORT=$1 screen -dm -L -S carla-carlaviz-$1 bash carlaviz/docker/run.sh
return 0;
fi
else echo "port $(($1+80)) or $(($1+81)) is unavailable" && return 1;
fi
}

run_srunner() {
if ! test_connection $(($1+60)); then
if python3  -m util.test_connection --port $1 --timeout 2; then
screen -dm -L -S carla-srunner-$1 python3 scenario_runner/scenario_runner.py --sync --scenario $2 --record $(realpath --relative-to="$SCENARIO_RUNNER_ROOT" "$PWD") --output --port $1 --trafficManagerPort $(($1+60))
return 0;
fi
else echo "port $(($1+60)) is unavailable" && return 1;
fi
}

run_autopilot() {
if python3 -m util.test_connection --port $1 --timeout 2; then
screen -dm -L -S carla-autopilot-$1 python3 autopilot.py --port $1 --tm-port $(($1+60))
return 0;
fi
}

thandler() {
echo "termination requested."
exit 1
}

trap thandler SIGTERM SIGINT SIGKILL

finish() {
echo "closing instances..."
screen -ls | grep 'carla-\(simulator\|carlaviz\|autopilot\|srunner\)' | cut -d. -f1 | awk '{print "pkill -9 -P " $1}' | bash
docker ps | grep carlaviz | cut -d. -f1 | awk '{print $1}' | xargs docker kill &> /dev/null
}

trap finish EXIT

echo "reading input file $1"
sleep 2
echo "preparing simulator and carlaviz instances"
sleep 2
while IFS=$'\t' read -r -a params
do
echo -e "launching carla-simulator with port ${params[0]} \c"
ret_str=$(run_carla ${params[0]})
ret_num=$?
if [ "$ret_num" -eq "0" ]; then echo -e "${GREEN}done!${NC}"; else echo -e "${RED}error: $ret_str${NC}" && exit $ret_num; fi
done < $1
echo "waiting for carla-simulator instances to be ready"
sleep 10
while IFS=$'\t' read -r -a params
do
while ! screen -ls | grep "carla-simulator-${params[0]}" &> /dev/null; do sleep 1; done
load_map ${params[0]} ${params[1]}
echo -e "launching carlaviz with carla-port ${params[0]} on localhost:$((${params[0]}+80)) \c"
ret_str=$(run_carlaviz ${params[0]})
ret_num=$?
if [ "$ret_num" -eq "0" ]; then echo -e "${GREEN}done!${NC}"; else echo -e "${RED}error: $ret_str${NC}" && exit $ret_num; fi
done < $1

echo "waiting carlaviz instances to be ready"
while IFS=$'\t' read -r -a params
do
echo "ok"
#while ! grep "Compiled successfully" screenlog-carla-carlaviz-${params[0]} &> /dev/null; do sleep 1; done
done < $1

sleep 2
echo "preparing scenarios"
sleep 2

while IFS=$'\t' read -r -a params
do
while ! screen -ls | grep "carla-simulator-${params[0]}" &> /dev/null; do sleep 1; done
echo -e "launching scenario-runner with carla-port ${params[0]} scenario ${params[1]} \c"
ret_str=$(run_srunner ${params[0]} ${params[1]})
ret_num=$?
if [ "$ret_num" -eq "0" ]; then echo -e "${GREEN}done!${NC}"; else echo -e "${RED}error: $ret_str${NC}" && exit $ret_num; fi
done < $1
sleep 2
while IFS=$'\t' read -r -a params
do
while ! screen -ls | grep "carla-srunner-${params[0]}" &> /dev/null || \
	! grep "ScenarioManager: Running scenario" screenlog-carla-srunner-${params[0]} &> /dev/null && \
	! grep "error" screenlog-carla-srunner-${params[0]} &> /dev/null; do sleep 1; done
echo -e "launching autopilot with carla-port ${params[0]} \c"
ret_str=$(run_autopilot ${params[0]})
ret_num=$?
if [ "$ret_num" -eq "0" ]; then echo -e "${GREEN}done!${NC}"; else echo -e "${RED}error: $ret_str${NC}" && exit $ret_num; fi
done < $1

sleep 2
echo "waiting for scenarios to finish"
while screen -ls | grep 'carla-\(srunner\|autopilot\)' &> /dev/null;
do
while IFS=$'\t' read -r -a params
do
if ! screen -ls | grep "carla-\(srunner\|autopilot\)-${params[0]}" &> /dev/null && screen -ls | grep "carla-simulator-${params[0]}" &> /dev/null;
then
echo "srunner or autopilot of ${params[0]} is dead so killing simulator"
screen -ls | grep "carla-simulator-${params[0]}" | cut -d. -f1 | awk '{print $1}' | xargs pkill -9 -P &> /dev/null
elif ! test_connection ${params[0]}; then echo "${params[0]} is not responding";
fi
done < $1
sleep 1
done

echo -e "${GREEN}jobs finished, logs are ready${NC}"

