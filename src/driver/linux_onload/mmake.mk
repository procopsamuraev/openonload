############################
# 
# EtherFabric linux kernel drivers 
#
#	onload_ip
#
############################


ONLOAD_SRCS	:= driver.c linux_cplane_netif.c timesync.c \
		tcp_sendpage.c driverlink_ip.c linux_stats.c pinbuf.c \
		linux_trampoline.c shmbuf.c compat.c \
		ossock_calls.c linux_sock_ops.c mmap.c \
		epoll_device.c terminate.c sigaction_calls.c onloadfs.c \
		dshm.c cplane.c cplane_prot.c


EFTHRM_SRCS	:= cplane_netif.c eplock_resource_manager.c \
		tcp_helper_endpoint.c tcp_helper_resource.c \
		tcp_helper_ioctl.c tcp_helper_mmap.c tcp_helper_sleep.c \
		tcp_helper_endpoint_move.c \
		tcp_filters.c oof_filters.c oof_onload.c \
		driverlink_filter.c ip_prot_rx.c ip_protocols.c \
		onload_nic.c id_pool.c dump_to_user.c iobufset.c \
		tcp_helper_cluster.c oof_interface.c

EFTHRM_HDRS	:= oo_hw_filter.h oof_impl.h tcp_filters_internal.h \
		tcp_helper_resource.h tcp_filters_deps.h oof_tproxy_ipproto.h \
		oof_onload_types.h

ifeq ($(LINUX),1)
EFTHRM_SRCS	+= tcp_helper_linux.c
endif

# Build host
CPPFLAGS += -DCI_BUILD_HOST=$(HOSTNAME)

IMPORT		:= $(EFTHRM_SRCS:%=../../lib/efthrm/%) \
		$(EFTHRM_HDRS:%=../../lib/efthrm/%)

IP_TARGET      := onload.o
IP_TARGET_SRCS := $(ONLOAD_SRCS) $(EFTHRM_SRCS)
ifdef OFE_TREE
IP_TARGET_SRCS += ofe_sysdep.c
endif

TARGETS		:= $(IP_TARGET)

# Need to import this here, because IMPORT is processed before we know 
# (easily) which architecture we are actually building for.
IMPORT         	   += linux_trampoline_asm_x86.S 

x86_TARGET_SRCS    := x86_linux_trampoline.o linux_trampoline_asm_x86.o

i386_TARGET_SRCS    := $(x86_TARGET_SRCS)

x86_64_TARGET_SRCS := $(x86_TARGET_SRCS)

powerpc_TARGET_SRCS    := ppc64_linux_trampoline_asm.o \
			ppc64_linux_trampoline.o ppc64_linux_trampoline_internal.o

arm64_TARGET_SRCS := aarch64_linux_trampoline.o aarch64_linux_trampoline_asm.o


######################################################
# linux kbuild support
#

all: $(BUILDPATH)/driver/linux_onload/Module.symvers \
	$(KBUILD_EXTRA_SYMBOLS)
	$(MMAKE_KBUILD_PRE_COMMAND)
ifdef OFE_TREE
ifdef CONFIG_X86_64
	cp $(OFE_TREE)/solsec_ofe/binary_k.o $(BUILDPATH)/driver/linux_onload/ofe.o
endif
endif
	$(MAKE) $(MMAKE_KBUILD_ARGS) M=$(CURDIR) \
		DO_EFAB_IP=1
	$(MMAKE_KBUILD_POST_COMMAND)
	cp -f onload.ko $(DESTPATH)/driver/linux



PREVIOUS_KSYM=$(BUILDPATH)/driver/linux_char/Module.symvers

$(BUILDPATH)/driver/linux_onload/Module.symvers: $(PREVIOUS_KSYM)
	cp $< $@

clean:
	@$(MakeClean)
	rm -rf *.ko Module.symvers .tmp_versions .*.cmd


ifdef MMAKE_IN_KBUILD

obj-m := $(IP_TARGET)

ifeq ($(ARCH),powerpc)
# RHEL5/PPC requires you to pass this, because by default its userspace
# is 32-bit, but its kernel was built with a 64-bit compiler!
EXTRA_CFLAGS+= -m64
endif

ifeq ($(ARCH),arm64)
# HACK: to circumvent build error on newever gcc/kernels on ARM (?)
EXTRA_CFLAGS+= -Wno-error=discarded-qualifiers
endif

ifeq ($(strip $(CI_PREBUILT_IPDRV)),)
onload-objs  := $(IP_TARGET_SRCS:%.c=%.o) $($(ARCH)_TARGET_SRCS:%.c=%.o)
onload-objs  += $(BUILD)/lib/transport/ip/ci_ip_lib.o	\
		$(BUILD)/lib/cplane/cplane_lib.o \
		$(BUILD)/lib/citools/citools_lib.o	\
		$(BUILD)/lib/ciul/ci_ul_lib.o

ifdef OFE_TREE
ifdef CONFIG_X86_64
onload-objs += ofe.o
endif
endif

else # CI_PREBUILT_IPDRV

onload-objs := onload.copy.o

$(BUILDPATH)/driver/linux_onload/onload.copy.o: $(CI_PREBUILT_IPDRV)
	@echo +++ Using prebuilt IP driver: $(CI_PREBUILT_IPDRV)
	cp $(CI_PREBUILT_IPDRV) $(BUILDPATH)/driver/linux_onload/onload.copy.o

endif # CI_PREBUILT_IPDRV

endif # MMAKE_IN_KBUILD
