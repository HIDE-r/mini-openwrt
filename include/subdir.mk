# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2007-2020 OpenWrt.org

ifeq ($(MAKECMDGOALS),prereq)
  SUBTARGETS:=prereq
  PREREQ_ONLY:=1
# For target/linux related target add dtb to selectively compile dtbs
else ifneq ($(filter target/linux/%,$(MAKECMDGOALS)),)
  SUBTARGETS:=$(DEFAULT_SUBDIR_TARGETS) dtb
else
  SUBTARGETS:=$(DEFAULT_SUBDIR_TARGETS)
endif

subtarget-default = $(filter-out ., \
	$(if $($(1)/builddirs-$(2)),$($(1)/builddirs-$(2)), \
	$(if $($(1)/builddirs-default),$($(1)/builddirs-default), \
	$($(1)/builddirs))))

define subtarget
  $(call warn_eval,$(1),t,T,$(1)/$(2): $($(1)/) $(foreach bd,$(call subtarget-default,$(1),$(2)),$(1)/$(bd)/$(2)))

endef

# 打印信息, 当$(3)指定的条件符合时, 正常退出;不符合时, 错误退出
#   当指定了 BUILD_LOG, 则会同时把日志写到 $(BUILD_LOG_DIR)/$(1)/error.txt;
# 1: path		目标路径
# 2: error message	需要打印错误信息
# 3: condition		条件不满足时, exit 1
define ERROR
	($(call MESSAGE, $(2)); $(if $(BUILD_LOG), echo "$(2)" >> $(BUILD_LOG_DIR)/$(1)/error.txt;) $(if $(3),, exit 1;))
endef

lastdir=$(word $(words $(subst /, ,$(1))),$(subst /, ,$(1)))
diralias=$(if $(findstring $(1),$(call lastdir,$(1))),,$(call lastdir,$(1)))

subdir_make_opts = \
	$(if $(SUBDIR_MAKE_DEBUG),-d) -r -C $(1) \
		BUILD_SUBDIR="$(1)" \
		BUILD_VARIANT="$(4)" \
		ALL_VARIANTS="$(5)"

# 进入子目录构建 $(if $(3),$(3)-)$(2) 目标
# 1: subdir		子目录
# 2: target		子目录的目标
# 3: build type
# 4: build variant
# 5: all variants	
log_make = \
	 $(if $(call debug,$(1),v),,@)+ \
	 $(if $(BUILD_LOG), \
		set -o pipefail; \
		mkdir -p $(BUILD_LOG_DIR)/$(1)$(if $(4),/$(4));) \
	$(SCRIPT_DIR)/time.pl "time: $(1)$(if $(4),/$(4))/$(if $(3),$(3)-)$(2)" \
	$$(SUBMAKE) $(subdir_make_opts) $(if $(3),$(3)-)$(2) \
		$(if $(BUILD_LOG),SILENT= 2>&1 | tee $(BUILD_LOG_DIR)/$(1)$(if $(4),/$(4))/$(if $(3),$(3)-)$(2).txt)

ifdef CONFIG_AUTOREMOVE
rebuild_check = \
	@-$$(NO_TRACE_MAKE) $(subdir_make_opts) check-depends >/dev/null 2>/dev/null; \
		$(if $(BUILD_LOG),mkdir -p $(BUILD_LOG_DIR)/$(1)$(if $(4),/$(4));) \
		$$(NO_TRACE_MAKE) $(if $(BUILD_LOG),-d) -q $(subdir_make_opts) .$(if $(3),$(3)-)$(2) \
			> $(if $(BUILD_LOG),$(BUILD_LOG_DIR)/$(1)$(if $(4),/$(4))/check-$(if $(3),$(3)-)$(2).txt,/dev/null) 2>&1 || \
			$$(SUBMAKE) $(subdir_make_opts) clean-build >/dev/null 2>/dev/null

endif

# 生成各级子目录的相关目标
#   如: 这里生成的 target/compile, 会调用到生成的 target/linux/compile, 最终进入 target/linux/ 目录下执行 compile 动作
# 
# Parameters: <subdir>
# 1. 遍历 $($(1)/builddirs) 每个目录
# 2. 遍历 每个 targets, 从 $(SUBTARGETS) $($(1)/subtargets) 获取
# 3. 生成 $(1)/$(bd)/$(btype)/$(target) 目标, buildtypes 一般是由 $(TMP_DIR)/.packagedeps 引入
# 4. 生成 $(1)/$(bd)/$(target) 目标, 调用到 build 目录下的 makefile 进行执行对应动作, 这个目标一般会由 $(1)/$(target) 作为依赖引用
# 5. 生成 $(1)/$(target) 目标
define subdir
  $(call warn,$(1),d,D $(1))
  $(foreach bd,$($(1)/builddirs),
    $(call warn,$(1),d,BD $(1)/$(bd))
    $(foreach target,$(SUBTARGETS) $($(1)/subtargets),
      $(foreach btype,$(buildtypes-$(bd)),
        $(call warn_eval,$(1)/$(bd),t,T,$(1)/$(bd)/$(btype)/$(target): $(if $(NO_DEPS)$(QUILT),,$($(1)/$(bd)/$(btype)/$(target)) $(call $(1)//$(btype)/$(target),$(1)/$(bd)/$(btype))))
		  $(call log_make,$(1)/$(bd),$(target),$(btype),$(filter-out __default,$(variant)),$($(1)/$(bd)/variants)) \
			|| $(call ERROR,$(2),   ERROR: $(1)/$(bd) [$(btype)] failed to build.,$(findstring $(bd),$($(1)/builddirs-ignore-$(btype)-$(target))))
        $(if $(call diralias,$(bd)),$(call warn_eval,$(1)/$(bd),l,T,$(1)/$(call diralias,$(bd))/$(btype)/$(target): $(1)/$(bd)/$(btype)/$(target)))
      )
      $(call warn_eval,$(1)/$(bd),t,T,$(1)/$(bd)/$(target): $(if $(NO_DEPS)$(QUILT),,$($(1)/$(bd)/$(target)) $(call $(1)//$(target),$(1)/$(bd))))
        $(foreach variant,$(filter-out *,$(if $(BUILD_VARIANT),$(BUILD_VARIANT),$(if $(strip $($(1)/$(bd)/variants)),$($(1)/$(bd)/variants),$(if $($(1)/$(bd)/default-variant),$($(1)/$(bd)/default-variant),__default)))),
			$(if $(BUILD_LOG),@mkdir -p $(BUILD_LOG_DIR)/$(1)/$(bd)/$(filter-out __default,$(variant)))
			$(if $($(1)/autoremove),$(call rebuild_check,$(1)/$(bd),$(target),,$(filter-out __default,$(variant)),$($(1)/$(bd)/variants)))
			$(call log_make,$(1)/$(bd),$(target),,$(filter-out __default,$(variant)),$($(1)/$(bd)/variants)) \
				|| $(call ERROR,$(1),   ERROR: $(1)/$(bd) failed to build$(if $(filter-out __default,$(variant)), (build variant: $(variant))).,$(findstring $(bd),$($(1)/builddirs-ignore-$(target)))) 
        )
      $(if $(PREREQ_ONLY)$(DUMP_TARGET_DB),,
        # aliases
        $(if $(call diralias,$(bd)),$(call warn_eval,$(1)/$(bd),l,T,$(1)/$(call diralias,$(bd))/$(target): $(1)/$(bd)/$(target)))
	  )
	)
  )
  $(foreach target,$(SUBTARGETS) $($(1)/subtargets),$(call subtarget,$(1),$(target)))
endef

ifndef DUMP_TARGET_DB
# 实际是对 $(1)/$(3) 目标的封装, 如 target/compile, 该目标由上面的 subdir 生成, 最后创建 stamp 文件表示目标构建成功
#
# Parameters: <subdir> <name> <target> <depends> <config options> <stampfile location>
# 1: subdir, 子目录名称
# 2: name, stamp 文件的名称 `.<name>_<target>`
# 3: target, 执行的动作，如：compile, install
# 4: depends，目标的依赖
# 5: config options
# 6: stampfile location, 标记文件的存放位置，如果为空，则默认存放在 `$(STAGING_DIR))/stamp/`
define stampfile
  $(1)/stamp-$(3):=$(if $(6),$(6),$(STAGING_DIR))/stamp/.$(2)_$(3)$(5)
  $$($(1)/stamp-$(3)): $(TMP_DIR)/.build $(4)
	@+$(SCRIPT_DIR)/timestamp.pl -n $$($(1)/stamp-$(3)) $(1) $(4) || \
		$(MAKE) $(if $(QUIET),--no-print-directory) $$($(1)/flags-$(3)) $(1)/$(3)
	@mkdir -p $$$$(dirname $$($(1)/stamp-$(3)))
	@touch $$($(1)/stamp-$(3))

  $$(if $(call debug,$(1),v),,.SILENT: $$($(1)/stamp-$(3)))

  .PRECIOUS: $$($(1)/stamp-$(3)) # work around a make bug

  $(1)//clean:=$(1)/stamp-$(3)/clean
  $(1)/stamp-$(3)/clean: FORCE
	@rm -f $$($(1)/stamp-$(3))

endef
endif
