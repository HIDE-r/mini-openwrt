# 概述

这里将会描述 build directory 的 Makefile 架构, 这个 Makefile 将会定义各个子级目录的依赖, 以及定义各个子级目录的构建目标

- target/Makefile
- package/Makefile
- tools/Makefile
- toolchains/Makefile

# 变量

## `curdir`

当前目录名, 如:

```makefile
curdir:=target
```

## `$(curdir)/subtargets`

除了默认的 target 还需要为子级构建目录定义的 target, 会生成目标 `$(curdir)/$(target)` 然后到子级构建目录下执行 `$(target)` 目标

```makefile
curdir:=target

$(curdir)/subtargets:=install
```

默认的 target 有:

```makefile
DEFAULT_SUBDIR_TARGETS:=clean download prepare compile update refresh prereq dist distcheck configure check check-depends
```

## `$(curdir)/builddirs`

子级构建目录的名称, 表示将会进入这些构建目录进行构建

```makefile
$(curdir)/builddirs:=linux sdk imagebuilder toolchain llvm-bpf
```

```shell
❯ ls -l target/
.rw-r--r-- 2.9k collin 17 Feb 11:05 Config.in
drwxr-xr-x    - collin 19 Feb 16:05 imagebuilder
drwxr-xr-x    - collin 19 Feb 11:08 linux
.rw-r--r-- 1.7k collin 24 Feb 15:59 Makefile
drwxr-xr-x    - collin 19 Feb 16:05 sdk
drwxr-xr-x    - collin 19 Feb 16:05 toolchain
```

## `$(curdir)/builddirs-$(target)`

指定 `$(curdir)/$(target)` 目标需要构建的子级目录.

会将`$(1)/$(bd)/$(target)`作为依赖关联到`$(curdir)/$(target)`, `$(1)/$(bd)/$(target)` 最后会进入 `$(1)/$(bd)` 执行 `$(target)`目标的构建

如:

```makefile
curdir:=target

$(curdir)/builddirs-install:=\
	linux \
	$(if $(CONFIG_SDK),sdk) \
	$(if $(CONFIG_IB),imagebuilder) \
	$(if $(CONFIG_MAKE_TOOLCHAIN),toolchain) \
	$(if $(CONFIG_SDK_LLVM_BPF),llvm-bpf)
```

## `$(curdir)/builddirs-default`

如果没有定义 `$(curdir)/builddirs-$(target)`, 则将会使用这里指定的 build 目录中的 target 目标, 作为依赖加入到 `$(curdir)/$(target)`

> 如果即没有定义 `$(curdir)/builddirs-$(target)` , 也没有定义 `$(curdir)/builddirs-default`, 
> 则 OpenWrt 会为每一个定义在 `$(curdir)/builddirs` 的目录作为 target 目标需要进入构建的目录

如:

```makefile
curdir:=target

$(curdir)/builddirs-default:=linux
```

## `$(curdir)/`

指定所有目标 `$(curdir)/$(target)` 的通用依赖

```makefile
define subtarget
  $(call warn_eval,$(1),t,T,$(1)/$(2): $($(1)/) $(foreach bd,$(call subtarget-default,$(1),$(2)),$(1)/$(bd)/$(2)))

endef
```

如:

```makefile
curdir:=tools

$(curdir)/ := .config prereq
```

表明 `tools/compile` , `tools/install` … 等类似的目标都需要依赖 `.config` 与 `prereq`

## `$(curdir)//$(target)`

指定所有 build 目录中特定的 target 的通用依赖

```makefile
# include/subdir.mk

define subdir
	...
      $(call warn_eval,$(1)/$(bd),t,T,$(1)/$(bd)/$(target): $(if $(NO_DEPS)$(QUILT),,$($(1)/$(bd)/$(target)) $(call $(1)//$(target),$(1)/$(bd))))
    ...
endef
```

如:

```makefile
curdir:=target

$(curdir)//compile = $(STAGING_DIR)/.prepared $(BIN_DIR)
```

表明所有子构建目录下的 compile动作 (如 `target/linux/compile` 与 `target/sdk/compile` ), 都必须依赖 `$(STAGING_DIR)/.prepared` 和  `$(BIN_DIR)`

## `$(curdir)/autoremove`

当构建失败时自动清除 build 目录下的构建目录, 需要开启 `CONFIG_AUTOREMOVE`

```makefile
ifdef CONFIG_AUTOREMOVE
rebuild_check = \
	@-$$(NO_TRACE_MAKE) $(subdir_make_opts) check-depends >/dev/null 2>/dev/null; \
		$(if $(BUILD_LOG),mkdir -p $(BUILD_LOG_DIR)/$(1)$(if $(4),/$(4));) \
		$$(NO_TRACE_MAKE) $(if $(BUILD_LOG),-d) -q $(subdir_make_opts) .$(if $(3),$(3)-)$(2) \
			> $(if $(BUILD_LOG),$(BUILD_LOG_DIR)/$(1)$(if $(4),/$(4))/check-$(if $(3),$(3)-)$(2).txt,/dev/null) 2>&1 || \
			$$(SUBMAKE) $(subdir_make_opts) clean-build >/dev/null 2>/dev/null

endif
```

如:

```makefile
curdir:=tools

$(curdir)/autoremove := 1
```

# 范例

这里以 target/Makefile 作为范例

```makefile
# 
# Copyright (C) 2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
curdir:=target

$(curdir)/subtargets:=install
$(curdir)/builddirs:=linux sdk imagebuilder toolchain llvm-bpf
$(curdir)/builddirs-default:=linux
$(curdir)/builddirs-install:=\
	linux \
	$(if $(CONFIG_SDK),sdk) \
	$(if $(CONFIG_IB),imagebuilder) \
	$(if $(CONFIG_MAKE_TOOLCHAIN),toolchain) \
	$(if $(CONFIG_SDK_LLVM_BPF),llvm-bpf)

$(curdir)/sdk/install:=$(curdir)/linux/install
$(curdir)/imagebuilder/install:=$(curdir)/linux/install

$(curdir)//compile = $(STAGING_DIR)/.prepared $(BIN_DIR)

$(eval $(call stampfile,$(curdir),target,prereq,.config))
$(eval $(call stampfile,$(curdir),target,compile,$(TMP_DIR)/.build))
$(eval $(call stampfile,$(curdir),target,install,$(TMP_DIR)/.build))

$($(curdir)/stamp-install): $($(curdir)/stamp-compile) 

$(eval $(call subdir,$(curdir)))

```
