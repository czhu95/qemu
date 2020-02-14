#!/bin/bash

QEMU=./build/x86_64-softmmu/qemu-system-x86_64
HDA=../panda/images/xpsp3.qcow2
VNC=0.0.0.0:5900

${QEMU} -hda ${HDA} -vnc ${VNC} -plugin ./hypersh/host/libhypersh.so -m 2G -smp 2,sockets=2 \
    -object memory-backend-ram,id=mem0,size=1G \
    -object memory-backend-ram,id=mem1,size=1G \
    -numa node,nodeid=0,memdev=mem0 -numa node,nodeid=1,memdev=mem1 \
    -numa cpu,node-id=0,socket-id=0 -numa cpu,node-id=1,socket-id=1
