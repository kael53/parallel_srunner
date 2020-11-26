#!/bin/bash
[ -z "$1" ] && echo "usage ./run_carla.sh port_number" && exit 1
SDL_VIDEODRIVER=offscreen SDL_HINT_CUDA_DEVICE=0 screen -dm -L -S carla-simulator-$1 $CARLA_ROOT/CarlaUE4/Binaries/Linux/CarlaUE4-Linux-Shipping -carla-rpc-port=$1 -opengl -benchmark -no-rendering

