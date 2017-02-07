#!/bin/sh


IP="192.168.1.100"
Port="8080"

while true
do
netstat -ant | grep $Port > port.txt

if ! test -s port.txt  ; then
break
fi

Port=$((Port+1))
done

docker run --name "$1" -p $Port:80 -itd nginx > gomi.txt

VAR=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $1)

sudo iptables -I DOCKER -s "$2" -d $VAR -j ACCEPT 

#echo "http://192.168.1.100:$Port"
echo "http://$IP:$Port"

