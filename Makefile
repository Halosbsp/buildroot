# halos bsp build root
VERSION = 1
PATCHLEVEL = 0
SUBLEVEL = 0
EXTRAVERSION = -release
NAME = King_Alex
#--------------------------------------------------------------
# Just run 'make menuconfig', configure stuff, then run 'make'.
# You shouldn't need to mess with anything beyond this point...
#--------------------------------------------------------------

# Delete default rules. We don't use them. This saves a bit of time.
.SUFFIXES:

# we want bash as shell
SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	 else if [ -x /bin/bash ]; then echo /bin/bash; \
	 else echo sh; fi; fi)

# Set O variable if not already done on the command line;
# or avoid confusing packages that can use the O=<dir> syntax for out-of-tree
# build by preventing it from being forwarded to sub-make calls.
ifneq ("$(origin O)", "command line")
O := $(CURDIR)/output
endif


# Remove the trailing '/.' from $(O) as it can be added by the makefile wrapper
# installed in the $(O) directory.
# Also remove the trailing '/' the user can set when on the command line.
override O := $(patsubst %/,%,$(patsubst %.,%,$(O)))
# Make sure $(O) actually exists before calling realpath on it; this is to
# avoid empty CANONICAL_O in case on non-existing entry.
CANONICAL_O := $(shell mkdir -p $(O) >/dev/null 2>&1)$(realpath $(O))

# gcc fails to build when the srcdir contains a '@'
ifneq ($(findstring @,$(CANONICAL_O)),)
$(error The build directory can not contain a '@')
endif

CANONICAL_CURDIR = $(realpath $(CURDIR))

# Make sure O= is passed (with its absolute canonical path) everywhere the
# toplevel makefile is called back.
EXTRAMAKEARGS := O=$(CANONICAL_O)

all:
.PHONY: all

export HALOS_VERSION := $(VERSION)$(if $(PATCHLEVEL),.$(PATCHLEVEL)$(if $(SUBLEVEL),.$(SUBLEVEL)))$(EXTRAVERSION)
# Save running make version since it's clobbered by the make package
RUNNING_MAKE_VERSION := $(MAKE_VERSION)

# Check for minimal make version (note: this check will break at make 10.x)
MIN_MAKE_VERSION = 3.81
ifneq ($(firstword $(sort $(RUNNING_MAKE_VERSION) $(MIN_MAKE_VERSION))),$(MIN_MAKE_VERSION))
$(error You have make '$(RUNNING_MAKE_VERSION)' installed. GNU make >= $(MIN_MAKE_VERSION) is required)
endif


# absolute path
TOPDIR := $(CURDIR)
HALOS_CONFIG_IN = Config.in
CONFIG = support/kconfig
DATE := $(shell date +%Y%m%d)

# Compute the full local version string so packages can use it as-is
# Need to export it, so it can be got from environment in children (eg. mconf)
export HALOS_VERSION_FULL := $(HALOS_VERSION)
###########
# when we need git ,we can use it to version
#$(shell $(TOPDIR)/support/scripts/setlocalversion)
#####

# List of targets and target patterns for which .config doesn't need to be read in
noconfig_targets := menuconfig
	
# Set variables related to in-tree or out-of-tree build.
# Here, both $(O) and $(CURDIR) are absolute canonical paths.
ifeq ($(O),$(CURDIR)/output)
CONFIG_DIR := $(CURDIR)
NEED_WRAPPER =
else
CONFIG_DIR := $(O)
NEED_WRAPPER = y
endif

# bash prints the name of the directory on 'cd <dir>' if CDPATH is
# set, so unset it here to not cause problems. Notice that the export
# line doesn't affect the environment of $(shell ..) calls.
export CDPATH :=

BASE_DIR := $(CANONICAL_O)
$(if $(BASE_DIR),, $(error output directory "$(O)" does not exist))

BUILD_DIR := $(BASE_DIR)/build
BINARIES_DIR := $(BASE_DIR)/images
BASE_TARGET_DIR := $(BASE_DIR)/target

# initial definition so that 'make clean' works for most users, even without
# .config. HOST_DIR will be overwritten later when .config is included.
HOST_DIR := $(BASE_DIR)/host

HALOS_CONFIG = $(CONFIG_DIR)/.config

# Pull in the user's configuration file
ifeq ($(filter $(noconfig_targets),$(MAKECMDGOALS)),)
include $(HALOS_CONFIG)
include $(TOPDIR)/envconfig.mk
endif

# To put more focus on warnings, be less verbose as default
# Use 'make V=1' to see the full commands
ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

ifeq ($(KBUILD_VERBOSE),1)
  Q =
ifndef VERBOSE
  VERBOSE = 1
endif
export VERBOSE
else
  Q = @
endif

# kconfig uses CONFIG_SHELL
CONFIG_SHELL := $(SHELL)

export SHELL CONFIG_SHELL Q KBUILD_VERBOSE

ifndef HALOS_HOSTAR
HALOS_HOSTAR := ar
endif
ifndef HALOS_HOSTAS
HALOS_HOSTAS := as
endif
ifndef HALOS_HOSTCC
HALOS_HOSTCC := gcc
HALOS_HOSTCC := $(shell which $(HALOS_HOSTCC) || type -p $(HALOS_HOSTCC) || echo gcc)
endif
HALOS_HOSTCC_NOCCACHE := $(HALOS_HOSTCC)
ifndef HALOS_HOSTCXX
HALOS_HOSTCXX := g++
HALOS_HOSTCXX := $(shell which $(HALOS_HOSTCXX) || type -p $(HALOS_HOSTCXX) || echo g++)
endif
HALOS_HOSTCXX_NOCCACHE := $(HALOS_HOSTCXX)
ifndef HALOS_HOSTCPP
HALOS_HOSTCPP := cpp
endif
ifndef HALOS_HOSTLD
HALOS_HOSTLD := ld
endif
ifndef HALOS_HOSTLN
HALOS_HOSTLN := ln
endif
ifndef HALOS_HOSTNM
HALOS_HOSTNM := nm
endif
ifndef HALOS_HOSTOBJCOPY
HALOS_HOSTOBJCOPY := objcopy
endif
ifndef HALOS_HOSTRANLIB
HALOS_HOSTRANLIB := ranlib
endif
HALOS_HOSTAR := $(shell which $(HALOS_HOSTAR) || type -p $(HALOS_HOSTAR) || echo ar)
HALOS_HOSTAS := $(shell which $(HALOS_HOSTAS) || type -p $(HALOS_HOSTAS) || echo as)
HALOS_HOSTCPP := $(shell which $(HALOS_HOSTCPP) || type -p $(HALOS_HOSTCPP) || echo cpp)
HALOS_HOSTLD := $(shell which $(HALOS_HOSTLD) || type -p $(HALOS_HOSTLD) || echo ld)
HALOS_HOSTLN := $(shell which $(HALOS_HOSTLN) || type -p $(HALOS_HOSTLN) || echo ln)
HALOS_HOSTNM := $(shell which $(HALOS_HOSTNM) || type -p $(HALOS_HOSTNM) || echo nm)
HALOS_HOSTOBJCOPY := $(shell which $(HALOS_HOSTOBJCOPY) || type -p $(HALOS_HOSTOBJCOPY) || echo objcopy)
HALOS_HOSTRANLIB := $(shell which $(HALOS_HOSTRANLIB) || type -p $(HALOS_HOSTRANLIB) || echo ranlib)
SED := $(shell which sed || type -p sed) -i -e

export HALOS_HOSTAR HALOS_HOSTAS HALOS_HOSTCC HALOS_HOSTCXX HALOS_HOSTLD
export HALOS_HOSTCC_NOCCACHE HALOS_HOSTCXX_NOCCACHE

# Determine the userland we are running on.
#
# Note that, despite its name, we are not interested in the actual
# architecture name. This is mostly used to determine whether some
# of the binary tools (e.g. pre-built external toolchains) can run
# on the current host. So we need to know if the userland we're
# running on can actually run those toolchains.
#
# For example, a 64-bit prebuilt toolchain will not run on a 64-bit
# kernel if the userland is 32-bit (e.g. in a chroot for example).
#
# So, we extract the first part of the tuple the host gcc was
# configured to generate code for; we assume this is our userland.
#
export HOSTARCH := $(shell LC_ALL=C $(HALOS_HOSTCC_NOCCACHE) -v 2>&1 | \
	sed -e '/^Target: \([^-]*\).*/!d' \
	    -e 's//\1/' \
	    -e 's/i.86/x86/' \
	    -e 's/sun4u/sparc64/' \
	    -e 's/arm.*/arm/' \
	    -e 's/sa110/arm/' \
	    -e 's/ppc64/powerpc64/' \
	    -e 's/ppc/powerpc/' \
	    -e 's/macppc/powerpc/' \
	    -e 's/sh.*/sh/' )

# When adding a new host gcc version in Config.in,
# update the HOSTCC_MAX_VERSION variable:
HALOS_HOSTCC_MAX_VERSION := 8

HALOS_HOSTCC_VERSION := $(shell V=$$($(HALOS_HOSTCC_NOCCACHE) --version | \
	sed -n -r 's/^.* ([0-9]*)\.([0-9]*)\.([0-9]*)[ ]*.*/\1 \2/p'); \
	[ "$${V%% *}" -le $(HALOS_HOSTCC_MAX_VERSION) ] || V=$(HALOS_HOSTCC_MAX_VERSION); \
	printf "%s" "$${V}")

# For gcc >= 5.x, we only need the major version.
ifneq ($(firstword $(HALOS_HOSTCC_VERSION)),4)
HALOS_HOSTCC_VERSION := $(firstword $(HALOS_HOSTCC_VERSION))
endif

ifeq ($(HAVE_DOT_CONFIG),y)
################################################################################
#
# Hide troublesome environment variables from sub processes
#
################################################################################
unexport CROSS_COMPILE
unexport ARCH
unexport CC
unexport LD
unexport AR
unexport CXX
unexport CPP
unexport RANLIB
unexport CFLAGS
unexport CXXFLAGS
unexport GREP_OPTIONS
unexport TAR_OPTIONS
unexport CONFIG_SITE
unexport QMAKESPEC
unexport TERMINFO
unexport MACHINE
unexport O
unexport GCC_COLORS
unexport PLATFORM
unexport OS

TAR_OPTIONS = $(call qstrip,$(HALOS_TAR_OPTIONS)) -xf

endif

ifneq ($(HOST_DIR),$(BASE_DIR)/host)
HOST_DIR_SYMLINK = $(BASE_DIR)/host
$(HOST_DIR_SYMLINK): $(BASE_DIR)
	ln -snf $(HOST_DIR) $(BASE_DIR)/host
endif

# Scripts in support/ or post-build scripts may need to reference
# these locations, so export them so it is easier to use
export HALOS_CONFIG
export HOST_DIR
export BINARIES_DIR
export BASE_DIR
# configuration
# ---------------------------------------------------------------------------

.PHONY: prepare-kconfig
prepare-kconfig: outputmakefile

$(BUILD_DIR)/buildroot-config/%onf:
	mkdir -p $(@D)/lxdialog
	$(MAKE) CC="$(HALOS_HOSTCC_NOCCACHE)" HOSTCC="$(HALOS_HOSTCC_NOCCACHE)" \
	    obj=$(@D) -C $(CONFIG) -f Makefile.br $(@F)

# We don't want to fully expand BR2_DEFCONFIG here, so Kconfig will
# recognize that if it's still at its default $(CONFIG_DIR)/defconfig
COMMON_CONFIG_ENV = \
	KCONFIG_AUTOCONFIG=$(BUILD_DIR)/buildroot-config/auto.conf \
	KCONFIG_AUTOHEADER=$(BUILD_DIR)/buildroot-config/autoconf.h \
	KCONFIG_TRISTATE=$(BUILD_DIR)/buildroot-config/tristate.config \
	HALOS_CONFIG=$(HALOS_CONFIG) \
	HOST_GCC_VERSION="$(HALOS_HOSTCC_VERSION)" \
	BUILD_DIR=$(BUILD_DIR) \
	SKIP_LEGACY=

menuconfig: $(BUILD_DIR)/buildroot-config/mconf prepare-kconfig
	@$(COMMON_CONFIG_ENV) $< $(HALOS_CONFIG_IN)


# outputmakefile generates a Makefile in the output directory, if using a
# separate output directory. This allows convenient use of make in the
# output directory.
.PHONY: outputmakefile
outputmakefile:
ifeq ($(NEED_WRAPPER),y)
	$(Q)$(TOPDIR)/support/scripts/mkmakefile $(TOPDIR) $(O)
endif


# customize build
checkenv:
	@if [ ! -e $(BINARIES_DIR) ]; then \
		mkdir $(BINARIES_DIR); \
	fi
	@if [ ! -e $(BASE_TARGET_DIR) ]; then \
		mkdir $(BASE_TARGET_DIR); \
	fi

.PHONY: uboot
uboot: checkenv
	@echo "start build uboot"
	make -C $(CURDIR)/$(UBOOT_PATH) uboot


.PHONY: clean
clean:
	rm -rf $(BASE_TARGET_DIR) $(BINARIES_DIR) $(HOST_DIR) $(HOST_DIR_SYMLINK) \
		$(BUILD_DIR) $(BINARIES_DIR)

.PHONY: distclean
distclean: clean
ifeq ($(O),$(CURDIR)/output)
	rm -rf $(O)
endif
	rm -rf $(HALOS_CONFIG) $(CONFIG_DIR)/.config.old $(CONFIG_DIR)/..config.tmp \
		$(CONFIG_DIR)/.auto.deps

.PHONY: help
help:
	@echo 'Cleaning:'
	@echo '  clean                  - delete all files created by build'
	@echo '  distclean              - delete all non-source files (including .config)'
	@echo
	@echo 'Build:'
	@echo '  all                    - make world'
	@echo
	@echo 'Configuration:'
	@echo '  menuconfig             - interactive curses-based configurator'

.PHONY: $(noconfig_targets)