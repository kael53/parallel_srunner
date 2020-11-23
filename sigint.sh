#!/bin/bash
[ -z "$1" ] && echo "usage ./sigint.sh query-keyword" && exit 1
screen -ls | grep $1 | cut -d. -f1 | awk -v cc="\\\'" '{print "screen -S " $1 " -X stuff ^C\n" }' | sh
