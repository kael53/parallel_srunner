#!/bin/bash
[ -z "$1" ] && echo "usage ./run.sh /path/to/instances.txt" && exit 1

function thandler() {
echo "termination requested."
exit 1
}

trap thandler SIGTERM SIGINT SIGKILL

function finish() {
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
echo "launching carla-simulator with port ${params[0]}"
bash run_carla.sh ${params[0]}
done < $1
sleep 10
while IFS=$'\t' read -r -a params
do
while ! screen -ls | grep "carla-simulator-${params[0]}" &> /dev/null; do sleep 1; done
echo "launching carlaviz with carla-port ${params[0]} on localhost:$((${params[0]}+80))"
bash run_carlaviz.sh ${params[0]}
done < $1

echo "waiting carlaviz instances to be ready"
while IFS=$'\t' read -r -a params
do
while ! cat "screenlog-carla-carlaviz-${params[0]}" | grep "Compiled successfully" &> /dev/null; do sleep 1; done
done < $1

sleep 2
echo "preparing scenarios"
sleep 2

while IFS=$'\t' read -r -a params
do
while ! screen -ls | grep "carla-simulator-${params[0]}" &> /dev/null; do sleep 1; done
echo "launching autopilot with carla-port ${params[0]}"
bash run_autopilot.sh ${params[0]}
done < $1
sleep 2
while IFS=$'\t' read -r -a params
do
while ! screen -ls | grep "carla-autopilot-${params[0]}" &> /dev/null; do sleep 1; done
echo "launching scenario-runner with carla-port ${params[0]} scenario ${params[1]}"
bash run_srunner.sh ${params[0]} ${params[1]}
done < $1

sleep 2
echo "waiting for scenarios to finish"
while screen -ls | grep 'carla-srunner' &> /dev/null;
do
while IFS=$'\t' read -r -a params
do
if ! screen -ls | grep "carla-srunner-${params[0]}" &> /dev/null && screen -ls | grep "carla-simulator-${params[0]}" &> /dev/null;
then
echo "srunner of ${params[0]} is dead so killing simulator"
screen -ls | grep "carla-simulator-${params[0]}" | cut -d. -f1 | awk '{print $1}' | xargs pkill -9 -P &> /dev/null
fi
done < $1
sleep 1
done

echo "jobs finished, logs are ready"
