#!/bin/sh

VAR=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $1)

sudo iptables -I DOCKER -s $2 -d $VAR -j ACCEPT


