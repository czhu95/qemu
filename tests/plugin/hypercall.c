/*
 * Copyright (C) 2018, Emilio G. Cota <cota@braap.org>
 *
 * License: GNU GPL, version 2 or later.
 *   See the COPYING file in the top-level directory.
 */
#include <inttypes.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>

#include <qemu-plugin.h>

#define HYPERCALL_NUM 777

QEMU_PLUGIN_EXPORT int qemu_plugin_version = QEMU_PLUGIN_VERSION;

static bool mem_cb_on = false;
static uint64_t mem_count = 0;
static enum qemu_plugin_mem_rw rw = QEMU_PLUGIN_MEM_RW;
static char buf[20] = "";

static void vcpu_syscall_cb(qemu_plugin_id_t id, unsigned int vcpu_index,
                            int64_t num, uint64_t a1, uint64_t a2,
                            uint64_t a3, uint64_t a4, uint64_t a5,
                            uint64_t a6, uint64_t a7, uint64_t a8)
{
    if (num == HYPERCALL_NUM) {
        mem_cb_on = !mem_cb_on;
        if (!qemu_plugin_virt_mem_rw(a1, buf, 19, false, false)) {
            fprintf(stderr,
                    "Fail to read guest virtual memory 0x%" PRIx64 "\n", a1);
        }
        fprintf(stderr, "guest> %s\n", buf);
    }
}

static void vcpu_mem(unsigned int cpu_index, qemu_plugin_meminfo_t meminfo,
                     uint64_t vaddr, void *udata)
{
    if (!mem_cb_on)
        return;

    if (mem_count++ % 10000 == 0) {
        struct qemu_plugin_hwaddr *hwaddr;
        hwaddr = qemu_plugin_get_hwaddr(meminfo, vaddr);
        uint64_t paddr = qemu_plugin_hwaddr_device_offset(hwaddr);

        fprintf(stderr, "%c %c 0x%" PRIx64 " 0x%" PRIx64 "\n",
                qemu_plugin_in_kernel() ? 'k' : 'u',
                qemu_plugin_mem_is_store(meminfo) ? 'w' : 'r', vaddr, paddr);
    }
}



static void vcpu_tb_trans(qemu_plugin_id_t id, struct qemu_plugin_tb *tb)
{
    size_t n = qemu_plugin_tb_n_insns(tb);
    size_t i;

    for (i = 0; i < n; i++) {
        struct qemu_plugin_insn *insn = qemu_plugin_tb_get_insn(tb, i);
        qemu_plugin_register_vcpu_mem_cb(insn, vcpu_mem,
                                         QEMU_PLUGIN_CB_NO_REGS,
                                         rw, NULL);
    }
}

QEMU_PLUGIN_EXPORT int qemu_plugin_install(qemu_plugin_id_t id,
                                           const qemu_info_t *info,
                                           int argc, char **argv)
{
    qemu_plugin_register_vcpu_syscall_cb(id, vcpu_syscall_cb);
    qemu_plugin_register_vcpu_tb_trans_cb(id, vcpu_tb_trans);
    // qemu_plugin_register_atexit_cb(id, plugin_exit, NULL);
    return 0;
}
