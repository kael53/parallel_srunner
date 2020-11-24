#!/bin/bash
[ -z "$1" ] && echo "usage ./run_carlaviz.sh port_number" && exit 1
screen -dm -L -S carla-carlaviz-$1 docker run --rm -p $(($1+80)):8080 -p $(($1+81)):8081 -it -e CARLAVIZ_HOST_IP=localhost -e CARLAVIZ_HOST_PORT=$(($1+81)) -e CARLA_SERVER_IP=172.17.0.1 -e CARLA_SERVER_PORT=$1 mjxu96/carlaviz:0.9.10
