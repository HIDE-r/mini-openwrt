# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2007-2020 OpenWrt.org

# debug flags:
#
# d: show subdirectory tree
# t: show added targets
# l: show legacy targets
# r: show autorebuild messages
# v: verbose (no .SILENCE for common targets)

ifeq ($(DUMP),)
  ifeq ($(DEBUG),all)
    build_debug:=dltvr
  else
    build_debug:=$(DEBUG)
  endif
endif

ifneq ($(DEBUG),)

# 检查是否命中调试flag
#   没有定义 $(DEBUG_SCOPE_DIR) 时, 检查 $(2) 是否存在于 $(build_debug)
#   当存在定义 $(DEBUG_SCOPE_DIR), 只有 $(1) 为 $(DEBUG_SCOPE_DIR)% 下的路径才会检查 $(2) 是否存在于 $(build_debug)
#
# 1: directory name
# 2: debug flag
define debug
$$(findstring $(2),$$(if $$(DEBUG_SCOPE_DIR),$$(if $$(filter $$(DEBUG_SCOPE_DIR)%,$(1)),$(build_debug)),$(build_debug)))
endef

# 当命中调试 flag 时, 打印 warning 信息
#   Note: warning 将会打印到 stderr 中
#
# 1: directory name
# 2: debug flag
# 3: debug message
define warn
$$(if $(call debug,$(1),$(2)),$$(warning $(3)))
endef

# 当命中调试 flag 时，执行命令
#
# 1: directory name
# 2: debug flag
# 3: command line
define debug_eval
$$(if $(call debug,$(1),$(2)),$(3))
endef

# 当命中调试 flag 时, 打印 warning 信息, 并执行命令
#   Note：即使没有设置 DEBUG flag, warn_eval 指定的命令也会执行
#
# 1: directory name
# 2: debug flag
# 3: debug message
# 4: command line
define warn_eval
$(call warn,$(1),$(2),$(3)	$(4))
$(4)
endef

else

debug:=
warn:=
debug_eval:=
warn_eval = $(4)

endif

