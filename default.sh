#!/bin/sh
./bin/slice add slice_default

#./bin/slice add_host --port 0x4:11 --mac 34:af:2c:25:75:21 --slice slice_default
./bin/slice add_host --port 0x1:1 --mac 9c:eb:e8:0d:5f:eb --slice slice_default
# ./bin/slice add_host --port 0x1:1 --mac 08:00:27:61:62:98 --slice slice_default
./bin/slice add_host --port 0x1:1 --mac 08:00:27:74:6d:e2 --slice slice_default
./bin/slice add_host --port 0x4:11 --mac 20:c6:eb:0d:ac:68 --slice slice_default
./bin/slice add_host --port 0x4:11 --mac 08:00:27:74:6d:e1 --slice slice_default
#./bin/slice add_host --port 0x2:4 --mac 08:00:27:74:6d:e3 --slice slice_default

