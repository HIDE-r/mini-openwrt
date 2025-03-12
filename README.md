# 概要

本项目基于 openwrt 24.10 进行构建框架的分析

```shell
git clone git://git.openwrt.org/openwrt/openwrt.git
git reset v24.10.0 --hard
```

# 目录及文件说明

| 目录       | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| config/    | kbuild 相关配置文件与脚本                                    |
| Config.in  | kbuild 入口                                                  |
| docker/    | 容器相关文件                                                 |
| docs/      | 当前项目的文档                                               |
| include/   | 其他辅助类 Makefile 的存放位置                               |
| LICENSES/  | 存放各类许可证                                               |
| Makefile   | 主 Makefile 入口                                             |
| package/   | 定义 openwrt 各类软件包构建方法                              |
| rules.mk   | 定义 Makefile 的通用规则, 通用变量等, 一般为全局使用才会放到此处 |
| scripts/   | 存放各类脚本                                                 |
| target/    | 各种目标架构平台的构建方法                                   |
| toolchain/ | 各个交叉编译软件包的构建方法                                 |
| tools/     | 各个宿主机软件包的构建方法                                   |

# 常用 Makefile 目标

**配置：**

| 目标              | 描述                                  |
| ----------------- | ------------------------------------- |
| defconfig         | 生成默认的 `.config`                  |
| oldconfig         | 基于当前已有的 `.config` 进行配置更新 |
| menuconfig        | openwrt 的菜单配置                    |
| nconfig           |                                       |
| xconfig           |                                       |
| kernel_menuconfig | linux 内核菜单配置                    |
| kernel_nconfig    |                                       |
| kernel_xconfig    |                                       |

**构建：**

| 目标 | 描述                  |
| ---- | --------------------- |
| make | 构建整个 openwrt 项目 |

**清理：**


| 目标      | 描述                                |
| --------- | ----------------------------------- |
| distclean | 清理所有生成的文件, 比 clean 更彻底 |
| clean     | 清理当前指定架构生成的文件          |


# 使用 docker 部署构建环境

```shell
cd docker
docker buildx build -t "mini_openwrt_build" -f Dockerfile .
```
# 构建主流程分析

以下将分析执行 make 后, makefile 的执行过程. 

查看 openwrt 的主框架Makefile, 由于 world 是第一个 makefile 目标, 故默认构建目标就是 world. 

开始构建进入时 OPENWRT_BUILD 为空, 故执行第一段逻辑, 可以看到第一段逻辑中仅仅是 include 了一些其他 makefile 进来, 并将 OPENWRT_BUILD 置为 1, 准备工作核心在 `include/toplevel.mk` 中

```makefile
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

## 构建环境检查及准备

查看 `include/toplevel.mk`, 这里有一个 [最后默认规则](https://www.gnu.org/software/make/manual/make.html#Last-Resort), 当目标没有定义规则命令时, 将会执行这个默认规则的命令. 

world 目标在第一段处理逻辑中并没有定义具体规则命令, 故会执行这里的规则命令. 下面对这三个规则命令进行分析.

```makefile
# include/toplevel.mk

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

### prereq

```makefile
@+$(PREP_MK) $(NO_TRACE_MAKE) -r -s prereq
```

实际命令可以替换为:

```makefile
OPENWRT_BUILD= QUIET=0 make V=s -r -s prereq
```

这个目标也定义在 `include/toplevel.mk`, 其行为是想要给 openwrt 准备依赖的环境

```makefile
# include/toplevel.mk

prereq:: prepare-tmpinfo .config
	@+$(NO_TRACE_MAKE) -r -s $@

prepare-tmpinfo: FORCE
	@+$(MAKE) -r -s $(STAGING_DIR_HOST)/.prereq-build $(PREP_MK)
	mkdir -p tmp/info feeds
	[ -e $(TOPDIR)/feeds/base ] || ln -sf $(TOPDIR)/package $(TOPDIR)/feeds/base
	$(_SINGLE)$(NO_TRACE_MAKE) -j1 -r -s -f include/scan.mk SCAN_TARGET="packageinfo" SCAN_DIR="package" SCAN_NAME="package" SCAN_DEPTH=5 SCAN_EXTRA=""
	$(_SINGLE)$(NO_TRACE_MAKE) -j1 -r -s -f include/scan.mk SCAN_TARGET="targetinfo" SCAN_DIR="target/linux" SCAN_NAME="target" SCAN_DEPTH=3 SCAN_EXTRA="" SCAN_MAKEOPTS="TARGET_BUILD=1"
	for type in package target; do \
		f=tmp/.$${type}info; t=tmp/.config-$${type}.in; \
		[ "$$t" -nt "$$f" ] || ./scripts/$${type}-metadata.pl $(_ignore) config "$$f" > "$$t" || { rm -f "$$t"; echo "Failed to build $$t"; false; break; }; \
	done
	[ tmp/.config-feeds.in -nt tmp/.packageauxvars ] || ./scripts/feeds feed_config > tmp/.config-feeds.in
	./scripts/package-metadata.pl mk tmp/.packageinfo > tmp/.packagedeps || { rm -f tmp/.packagedeps; false; }
	./scripts/package-metadata.pl pkgaux tmp/.packageinfo > tmp/.packageauxvars || { rm -f tmp/.packageauxvars; false; }
	./scripts/package-metadata.pl usergroup tmp/.packageinfo > tmp/.packageusergroup || { rm -f tmp/.packageusergroup; false; }
	touch $(TOPDIR)/tmp/.build


.config: ./scripts/config/conf $(if $(CONFIG_HAVE_DOT_CONFIG),,prepare-tmpinfo)
	@+if [ \! -e .config ] || ! grep CONFIG_HAVE_DOT_CONFIG .config >/dev/null; then \
		[ -e $(HOME)/.openwrt/defconfig ] && cp $(HOME)/.openwrt/defconfig .config; \
		$(_SINGLE)$(NO_TRACE_MAKE) menuconfig $(PREP_MK); \
	fi
```

- `prepare-tmpinfo`, 这个目标的行为稍微会复杂一点, 调用 `$(STAGING_DIR_HOST)/.prereq-build` 检查openwrt的必要依赖工具和环境并将相关工具安装到 staging 目录, 然后使用 `include/scan.mk` 收集 target 和 package 目录的信息到 tmp 目录, 最后使用 `scripts/package-metadata.pl` 过滤收集的信息后生成 tmp 目录重要的几个文件: `tmp/.packagedeps`, `tmp/.packageauxvars`, `tmp/.packageusergroup`.

- `.config`, 这个目标就是调用 menuconfig 生成用户的 openwrt 配置



### .config 的检查

```makefile
	@( \
		cp .config tmp/.config; \
		./scripts/config/conf $(KCONF_FLAGS) --defconfig=tmp/.config -w tmp/.config Config.in > /dev/null 2>&1; \
		if ./scripts/kconfig.pl '>' .config tmp/.config | grep -q CONFIG; then \
			printf "$(_R)WARNING: your configuration is out of sync. Please run make menuconfig, oldconfig or defconfig!$(_N)\n" >&2; \
		fi \
	)
```

### 调用到主框架构建

```makefile
	@+$(ULIMIT_FIX) $(SUBMAKE) -r $@ $(if $(WARN_PARALLEL_ERROR), || { \
		printf "$(_R)Build failed - please re-run with -j1 to see the real error message$(_N)\n" >&2; \
		false; \
	} )
```

对于 world 的目标构建将会扩展为以下的形式:

```makefile
_limit=`ulimit -n`;
[ "$_limit" = "unlimited" -o "$_limit" -ge 1024 ] || ulimit -n 1024;
umask 022;

cmd() { 
	>/dev/null 2>&1 make -s "$@" < /dev/null || { echo "make $*: build failed. Please re-run make with -j1 V=s or V=sc for a higher verbosity level to see what's going on"; false; }
} 8>&1 9>&2;

cmd -r world
```

来到这里说明环境已经准备好了, 将会开始 openwrt 各种内容构建, 这里就是真正构建的第一层 Makefile 的进入, 一旦最终构建失败会打印后面常见的信息, 并从这里退出.

```shell
build failed. Please re-run make with -j1 V=s or V=sc for a higher verbosity level to see what's going on
```

## 主框架构建分析

```makefile
prepare: .config $(tools/stamp-compile) $(toolchain/stamp-compile)
	$(_SINGLE)$(SUBMAKE) -r buildinfo

world: prepare $(target/stamp-compile) $(package/stamp-compile) $(package/stamp-install) $(target/stamp-install) FORCE
	$(_SINGLE)$(SUBMAKE) -r package/index
	$(_SINGLE)$(SUBMAKE) -r json_overview_image_info
	$(_SINGLE)$(SUBMAKE) -r checksum
ifneq ($(CONFIG_CCACHE),)
	$(STAGING_DIR_HOST)/bin/ccache -s
endif
```

- `prepare`,  包含 `$(tools/stamp-compile)` 主机工具的构建和`$(toolchain/stamp-compile)`交叉编译工具链的构建
- `$(target/stamp-compile)`, SDK 或 kernel 的构建

- `$(package/stamp-compile)`, 各种内核模块与应用层软件包的构建
- `$(package/stamp-install)`, 创建 rootfs , 将各个软件包安装到 rootfs
- `$(target/stamp-install)`,  制作 firmware

- 最后 world 的规则命令中执行收集各种信息的收尾工作

# 其他文档

[docs](./docs)



<a href="https://www.buymeacoffee.com/LKangN" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
