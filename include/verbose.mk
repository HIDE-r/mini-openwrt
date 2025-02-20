# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2006-2020 OpenWrt.org
# V=1	只打印到标准输出, 不把标准出错打印到标准输出
# V=99	打印详细的构建过程

ifndef OPENWRT_VERBOSE
  OPENWRT_VERBOSE:=
endif
ifeq ("$(origin V)", "command line")
  OPENWRT_VERBOSE:=$(V)
endif

ifeq ($(OPENWRT_VERBOSE),1)
  OPENWRT_VERBOSE:=w
endif
ifeq ($(OPENWRT_VERBOSE),99)
  OPENWRT_VERBOSE:=s
endif

ifeq ($(NO_TRACE_MAKE),)
NO_TRACE_MAKE := $(MAKE) V=s$(OPENWRT_VERBOSE)
export NO_TRACE_MAKE
endif

ifeq ($(IS_TTY),1)
  ifneq ($(strip $(NO_COLOR)),1)
    _Y:=\\033[33m
    _R:=\\033[31m
    _N:=\\033[m
  endif
endif

define ERROR_MESSAGE
  { \
	printf "$(_R)%s$(_N)\n" "$(1)" >&9 || \
	printf "$(_R)%s$(_N)\n" "$(1)"; \
  } >&2 2>/dev/null
endef

ifeq ($(findstring s,$(OPENWRT_VERBOSE)),)
# V= or V=1
  define MESSAGE
	{ \
		printf "$(_Y)%s$(_N)\n" "$(1)" >&8 || \
		printf "$(_Y)%s$(_N)\n" "$(1)"; \
	} 2>/dev/null
  endef

  ifeq ($(QUIET),1)
# 第二次进入, 打印信息, 将继承第一次设置的 make 参数 -s, 故也不会打印规则命令的执行
# make[1] world
    ifneq ($(CURDIR),$(TOPDIR))
      _DIR:=$(patsubst $(TOPDIR)/%,%,${CURDIR})
    else
      _DIR:=
    endif
    _MESSAGE:=$(if $(MAKECMDGOALS),$(shell \
		$(call MESSAGE, make[$(MAKELEVEL)]$(if $(_DIR), -C $(_DIR)) $(MAKECMDGOALS)); \
    ))
    ifneq ($(strip $(_MESSAGE)),)
      $(info $(_MESSAGE))
    endif
    SUBMAKE=$(MAKE)
  else
# 第一次进入, SUBMAKE 设置为 make 的 wrapper 函数, -s 将不打印规则命令的执行
    SILENT:=>/dev/null $(if $(findstring w,$(OPENWRT_VERBOSE)),,2>&1)
    export QUIET:=1
    SUBMAKE=cmd() { $(SILENT) $(MAKE) -s "$$@" < /dev/null || { echo "make $$*: build failed. Please re-run make with -j1 V=s or V=sc for a higher verbosity level to see what's going on"; false; } } 8>&1 9>&2; cmd
  endif

  .SILENT: $(MAKECMDGOALS)
else
# V=99
  SUBMAKE=$(MAKE) -w
  define MESSAGE
    printf "%s\n" "$(1)"
  endef
endif
