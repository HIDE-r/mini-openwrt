这里假设 openwrt 项目根目录为：`/home/build`

# 目录及文件相关

| 变量                |                             定义                             | 示例                                                         | 描述                                                         |
| ------------------- | :----------------------------------------------------------: | ------------------------------------------------------------ | ------------------------------------------------------------ |
| TOPDIR              |                     `TOPDIR:=${CURDIR}`                      | /home/build                                                  | 项目的顶级目录                                               |
| BUILD_LOG_DIR       | `BUILD_LOG_DIR:=$(if $(call qstrip,$(CONFIG_BUILD_LOG_DIR)),$(call qstrip,$(CONFIG_BUILD_LOG_DIR)),$(TOPDIR)/logs)` | /home/build/logs                                             | 保存构建日志的目录<br />如果定义了 `CONFIG_BUILD_LOG_DIR`, 则会使用配置值, <br />否则使用 `$(TOPDIR)/bin` |
| OUTPUT_DIR          | `OUTPUT_DIR:=$(if $(call qstrip,$(CONFIG_BINARY_FOLDER)),$(call qstrip,$(CONFIG_BINARY_FOLDER)),$(TOPDIR)/bin)` | /home/build/bin                                              | 如果定义了 `CONFIG_BINARY_FOLDER`, 则会使用配置值, <br />否则使用 `$(TOPDIR)/bin` |
| BIN_DIR             |    `BIN_DIR:=$(OUTPUT_DIR)/targets/$(BOARD)/$(SUBTARGET)`    | /home/build/bin/targets/x86/64/                              |                                                              |
| BUILD_DIR           |      `BUILD_DIR:=$(BUILD_DIR_BASE)/$(TARGET_DIR_NAME)`       | /home/build/build_dir/target-x86_64_musl                     |                                                              |
| PACKAGE_DIR         |              `PACKAGE_DIR?=$(BIN_DIR)/packages`              | /home/build/bin/targets/x86/64/packages                      |                                                              |
| TARGET_ROOTFS_DIR   | `TARGET_ROOTFS_DIR?=$(if $(call qstrip,$(CONFIG_TARGET_ROOTFS_DIR)),$(call qstrip,$(CONFIG_TARGET_ROOTFS_DIR)),$(BUILD_DIR))` | /home/build/build_dir/target-x86_64_musl                     | 如果定义了 `CONFIG_TARGET_ROOTFS_DIR`, 则会使用配置值, <br />否则使用 `$(BUILD_DIR)` |
| TARGET_DIR          |       `TARGET_DIR:=$(TARGET_ROOTFS_DIR)/root-$(BOARD)`       | /home/build/build_dir/target-x86_64_musl/root-x86            |                                                              |
| TARGET_DIR_ORIG     |                                                              | /home/build/build_dir/target-x86_64_musl/root.orig-x86       |                                                              |
| STAGING_DIR         |   `STAGING_DIR:=$(TOPDIR)/staging_dir/$(TARGET_DIR_NAME)`    | /home/build/staging_dir/target-x86_64_musl                   | 对应架构的暂存目录                                           |
| STAGING_DIR_ROOT    |       `STAGING_DIR_ROOT:=$(STAGING_DIR)/root-$(BOARD)`       | /home/build/staging_dir/target-x86_64_musl/root-x86          | 暂存目录下的 rootfs 目录                                     |
| STAGING_DIR_HOST    |    `STAGING_DIR_HOST:=$(abspath $(STAGING_DIR)/../host)`     | /home/build/staging_dir/host                                 | host tools 的安装路径                                        |
| STAGING_DIR_HOSTPKG | `STAGING_DIR_HOSTPKG:=$(abspath $(STAGING_DIR)/../hostpkg)`  | /home/build/staging_dir/hostpkg                              | package 目录下提供的 host tool 将会安装到 hostpkg            |
| HOST_BUILD_DIR      |                                                              | /home/build/build_dir/host/flock-2.18                        | `HOST_BUILD_DIR ?= $(BUILD_DIR_HOST)/$(PKG_NAME)$(if $(PKG_VERSION),-$(PKG_VERSION))` |
| PKG_BUILD_DIR       | `$(BUILD_DIR)/$(if $(BUILD_VARIANT),$(PKG_NAME)-$(BUILD_VARIANT)/)$(PKG_NAME)$(if $(PKG_VERSION),-$(PKG_VERSION))` | /home/build/build_dir/target-x86_64_musl/netifd-2021-07-26-440eb064 |                                                              |
| PKG_INSTALL_DIR     |               `$(PKG_BUILD_DIR)/ipkg-install`                | /home/build/build_dir/target-x86_64_musl/netifd-2021-07-26-440eb064/ipkg-install |                                                              |
| PKG_INSTALL_STAMP   |                                                              | /home/build/staging_dir/target-x86_64_musl/pkginfo/netifd.default.install |                                                              |
| PKG_INFO_DIR        |                   `$(STAGING_DIR)/pkginfo`                   | /home/build/staging_dir/target-x86_64_musl/pkginfo           |                                                              |
| KERNEL_BUILD_DIR    | `$(BUILD_DIR)/linux-$(BOARD)$(if $(SUBTARGET),_$(SUBTARGET))` | /home/build/build_dir/target-x86_64_musl/linux-x86_64        |                                                              |
| LINUX_DIR           |         `$(KERNEL_BUILD_DIR)/linux-$(LINUX_VERSION)`         | /home/build/build_dir/target-x86_64_musl/linux-x86_64/linux-5.4.101/ |                                                              |

# stamp 标志文件

用于表示某些任务已经完成

| 变量             |                             定义                             | 示例                                                         | 描述 |
| ---------------- | :----------------------------------------------------------: | ------------------------------------------------------------ | ---- |
| STAMP_BUILT      |                  `$(PKG_BUILD_DIR)/.built`                   | /home/build/build_dir/target-x86_64_musl/netifd-2021-07-26-440eb064/.built |      |
| STAMP_CONFIGURED | `$(PKG_BUILD_DIR)/.configured$(if $(DUMP),,_$(call confvar,$(PKG_CONFIG_DEPENDS)))` | /home/build/build_dir/target-x86_64_musl/netifd-2021-07-26-440eb064/.configured_68b329da9893e34099c7d8ad5cb9c940 |      |
| STAMP_INSTALLED  | `$(STAGING_DIR)/stamp/.$(PKG_DIR_NAME)$(if $(BUILD_VARIANT),.$(BUILD_VARIANT),)_installed` | /home/build/staging_dir/target-x86_64_musl/stamp/.netifd_installed |      |
