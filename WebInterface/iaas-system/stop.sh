#!bin/bash

VAR=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $1)
#VAR=172.17.0.2

docker stop $1
docker rm $1

sudo iptables -L DOCKER --line-numbers > docker.txt

sudo sed -e "1,2d" docker.txt > docker2.txt

grep -e "$VAR" -n docker2.txt | sed -e 's/:.*//g' > delete.txt

sort -r delete.txt > delete2.txt

TESTFILE=delete2.txt
while read line; do
sudo iptables -D DOCKER $line
done < $TESTFILE


