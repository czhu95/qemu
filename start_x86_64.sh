#!/bin/bash
CORES=2

while getopts "dn:" opt; do
    case "$opt" in
        d)
            debug=1
            ;;
        n)
            CORES=$OPTARG
            ;;
    esac
done

if [ -z $debug ]
then
    QEMU=./build/x86_64-softmmu/qemu-system-x86_64
    PLUGIN=./hypersh/host/libhypersh.so
else
    QEMU=./build/debug/x86_64-softmmu/qemu-system-x86_64
    PLUGIN=./hypersh/host/libhypersh.sod
fi

HDA=../panda/images/xpsp3.qcow2
VNC=0.0.0.0:5900
MEM=${CORES}G
SMP=${CORES},sockets=${CORES}
for c in $(seq 0 $((CORES-1))); do
    SMP+=" -object memory-backend-ram,id=mem${c},size=1G"
    SMP+=" -numa node,nodeid=${c},memdev=mem${c}"
    SMP+=" -numa cpu,node-id=${c},socket-id=${c}"
done

QEMU_ARGS="-hda ${HDA} -vnc ${VNC} -plugin ${PLUGIN} -m ${MEM} -smp ${SMP}"
echo ${QEMU} ${QEMU_ARGS}

if [ -z $debug ]
then
    ${QEMU} ${QEMU_ARGS}
else
    gdb --args ${QEMU} ${QEMU_ARGS}
fi
