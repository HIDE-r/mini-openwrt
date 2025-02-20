# 
# Copyright (C) 2007 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
curdir:=target

# 除了默认目标外，需要定义的子目标
$(curdir)/subtargets:=install

# 需要编译的target目录下的子目录
$(curdir)/builddirs:=linux sdk imagebuilder toolchain llvm-bpf

# 给目标的依赖
# 如：builddirs-install, 则是给 target/install 的依赖
# target/install: target/linux/install ....
#
#   如果对应目标没有对应变量作为依赖，将会使用builddirs-default作为依赖
#   如果没有builddirs-default,则会寻找builddirs的内容作为依赖
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

# /home/Project/openwrt/staging_dir/target-x86_64_musl/stamp/.target_prereq: /home/Project/openwrt/tmp/.build .config
$(eval $(call stampfile,$(curdir),target,prereq,.config))

# /home/Project/openwrt/staging_dir/target-x86_64_musl/stamp/.target_compile: /home/Project/openwrt/tmp/.build $(TMP_DIR)/.build
$(eval $(call stampfile,$(curdir),target,compile,$(TMP_DIR)/.build))

# /home/Project/openwrt/staging_dir/target-x86_64_musl/stamp/.target_install: /home/Project/openwrt/tmp/.build $(TMP_DIR)/.build
$(eval $(call stampfile,$(curdir),target,install,$(TMP_DIR)/.build))

$($(curdir)/stamp-install): $($(curdir)/stamp-compile) 

$(eval $(call subdir,$(curdir)))
