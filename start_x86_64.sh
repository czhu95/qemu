#!/bin/bash
CORES=2
NODES=1

PLUGINS=(hypersh pmem mcount trace slomo)

while getopts "dn:c:" opt; do
    case "$opt" in
        d)
            debug=1
            ;;
        n)
            NODES=$OPTARG
            ;;
        c)
            CORES=$OPTARG
            ;;
    esac
done

if [ -z $debug ]; then
    QEMU=./build/x86_64-softmmu/qemu-system-x86_64
    PLUGIN_SUFFIX=""
else
    QEMU=./build/debug/x86_64-softmmu/qemu-system-x86_64
    PLUGIN_SUFFIX="d"
fi

HDA=./images/xpsp3.qcow2
VNC=0.0.0.0:5900
SMP=${CORES},sockets=${NODES}
CPUS_PER_NODE=$((CORES/NODES))
MEM_PER_NODE=16
MEM=$((NODES*MEM_PER_NODE))
for n in $(seq 0 $((NODES-1))); do
    CPUS=$((CPUS_PER_NODE*n))-$((CPUS_PER_NODE*(n+1)-1))
    SMP+=" -object memory-backend-ram,id=mem${n},size=${MEM_PER_NODE}G"
    SMP+=" -numa node,nodeid=${n},memdev=mem${n},cpus=${CPUS}"
done

for p in ${PLUGINS[@]}; do
    PLUGIN_ARGS+=" -plugin ./hypersh/host/lib${p}.so${PLUGIN_SUFFIX}"
done

QEMU_ARGS="-hda ${HDA} -vnc ${VNC} ${PLUGIN_ARGS} -m ${MEM}G -smp ${SMP}"
echo ${QEMU} ${QEMU_ARGS}

if [ -z $debug ]; then
    ${QEMU} ${QEMU_ARGS}
else
    gdb --args ${QEMU} ${QEMU_ARGS}
fi
