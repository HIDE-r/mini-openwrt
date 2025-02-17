# 概要

本项目基于 openwrt 24.10 进行构建框架的分析

```shell
git clone git://git.openwrt.org/openwrt/openwrt.git
git reset v24.10.0 --hard
```

# 目录及文件

# 目标人群

对 openwrt 有开发已有开发经验, 希望能深入研究 openwrt 的构建流程的开发者

# 使用 docker 部署构建环境

```shell
docker buildx build -t "mini_openwrt_build" -f Dockerfile .
```

# 构建主流程分析

以下将分析执行 make 后, makefile 的执行过程

## 构建环境检查及准备

查看 openwrt 的主Makefile, 由于 world 是第一个 makefile 目标, 故默认构建目标就是 world. 开始构建进入时 OPENWRT_BUILD 为空, 故执行第一段逻辑, 可以看到第一段逻辑中仅仅是 include 了一些其他 makefile 进来, 准备工作核心在 `include/toplevel.mk` 中

```make
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2007 OpenWrt.org

TOPDIR:=${CURDIR}
LC_ALL:=C
LANG:=C
TZ:=UTC
export TOPDIR LC_ALL LANG TZ

empty:=
space:= $(empty) $(empty)
$(if $(findstring $(space),$(TOPDIR)),$(error ERROR: The path to the OpenWrt directory must not include any spaces))

world:

DISTRO_PKG_CONFIG:=$(shell $(TOPDIR)/scripts/command_all.sh pkg-config | grep -e '/usr' -e '/nix/store' -m 1)

export ORIG_PATH:=$(if $(ORIG_PATH),$(ORIG_PATH),$(PATH))
export PATH:=$(if $(STAGING_DIR),$(abspath $(STAGING_DIR)/../host/bin),$(TOPDIR)/staging_dir/host/bin):$(PATH)

ifneq ($(OPENWRT_BUILD),1)
  _SINGLE=export MAKEFLAGS=$(space);

  override OPENWRT_BUILD=1
  export OPENWRT_BUILD
  GREP_OPTIONS=
  export GREP_OPTIONS
  CDPATH=
  export CDPATH
  include $(TOPDIR)/include/debug.mk
  include $(TOPDIR)/include/depends.mk
  include $(TOPDIR)/include/toplevel.mk
else
    ...
    ...
endif
```

查看 `include/toplevel.mk`, 这里有一个 [最后默认规则](https://www.gnu.org/software/make/manual/make.html#Last-Resort), 当目标没有定义规则命令时, 将会执行这个默认规则的命令. world 目标在第一段处理逻辑中并没有定义具体规则命令, 故会执行这里的规则命令.

```makefile
%::
	@+$(PREP_MK) $(NO_TRACE_MAKE) -r -s prereq
	@( \
		cp .config tmp/.config; \
		./scripts/config/conf $(KCONF_FLAGS) --defconfig=tmp/.config -w tmp/.config Config.in > /dev/null 2>&1; \
		if ./scripts/kconfig.pl '>' .config tmp/.config | grep -q CONFIG; then \
			printf "$(_R)WARNING: your configuration is out of sync. Please run make menuconfig, oldconfig or defconfig!$(_N)\n" >&2; \
		fi \
	)
	@+$(ULIMIT_FIX) $(SUBMAKE) -r $@ $(if $(WARN_PARALLEL_ERROR), || { \
		printf "$(_R)Build failed - please re-run with -j1 to see the real error message$(_N)\n" >&2; \
		false; \
	} )
```
