# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2006-2020 OpenWrt.org

ifneq ($(__prereq_inc),1)
__prereq_inc:=1

# 定义 prereq 的规则命令, 存在错误日志时进行打印并删除文件
prereq:
	if [ -f $(TMP_DIR)/.prereq-error ]; then \
		echo; \
		cat $(TMP_DIR)/.prereq-error; \
		rm -f $(TMP_DIR)/.prereq-error; \
		echo; \
		false; \
	fi

.SILENT: prereq
endif

PREREQ_PREV=

# 生成定义一些用于检查的目标, 并将其作为依赖添加到 prereq 目标中
# 其中 prereq-$(1) 用于调用check-$(1)检查并打印结果, 并且它会依赖于上一个 prereq-$(1) 目标
# check-$(1) 会调用 Require/$(1), Require/$(1) 这个目标通常由下面不同的场景进行实现
# 1: display name		定义的目标名
# 2: error message		失败时打印的log
#
# example:
# Checking 'working-make'... ok.
# Checking 'case-sensitive-fs'... ok.
# Checking 'proper-umask'... ok.
# Checking 'gcc'... ok.
# Checking 'working-gcc'... ok.
# Checking 'g++'... ok.
define Require
  export PREREQ_CHECK=1
  ifeq ($$(CHECK_$(1)),)
    prereq: prereq-$(1)

    prereq-$(1): $(if $(PREREQ_PREV),prereq-$(PREREQ_PREV)) FORCE
		printf "Checking '$(1)'... "
		if $(NO_TRACE_MAKE) -f $(firstword $(MAKEFILE_LIST)) check-$(1) PATH="$(ORIG_PATH)" >/dev/null 2>/dev/null; then \
			echo 'ok.'; \
		elif $(NO_TRACE_MAKE) -f $(firstword $(MAKEFILE_LIST)) check-$(1) PATH="$(ORIG_PATH)" >/dev/null 2>/dev/null; then \
			echo 'updated.'; \
		else \
			echo 'failed.'; \
			echo "$(PKG_NAME): $(strip $(2))" >> $(TMP_DIR)/.prereq-error; \
		fi

    check-$(1): FORCE
	  $(call Require/$(1))
    CHECK_$(1):=1

    .SILENT: prereq-$(1) check-$(1)
    .NOTPARALLEL:
  endif

  PREREQ_PREV=$(1)
endef


define RequireCommand
  define Require/$(1)
    command -v $(1)
  endef

  $$(eval $$(call Require,$(1),$(2)))
endef

define RequireHeader
  define Require/$(1)
    [ -e "$(1)" ]
  endef

  $$(eval $$(call Require,$(1),$(2)))
endef

# 通过写一个简单的 c code 调用头文件中的函数来判断系统中是否有指定的头文件, 以及库文件
# 1: header to test					需要测试的头文件
# 2: failure message					失败时打印的log
# 3: optional compile time test				头文件中的测试函数
# 4: optional link library test (example -lncurses)	测试函数需要链接的库
define RequireCHeader
  define Require/$(1)
    echo 'int main(int argc, char **argv) { $(3); return 0; }' | gcc -include $(1) -x c -o $(TMP_DIR)/a.out - $(4)
  endef

  $$(eval $$(call Require,$(1),$(2)))
endef

define QuoteHostCommand
'$(subst ','"'"',$(strip $(1)))'
endef

# 用于判断 host 的工具是否符合条件
#
# 1: display name 		定义的目标名
# 2: failure message 		失败时打印的log
# 3: test 			用于判断程序满足条件的命令
# example:
#
# $(eval $(call TestHostCommand,working-make, \
# 	Please install GNU make v4.1 or later., \
# 	$(MAKE) -v | grep -E 'Make (4\.[1-9]|[5-9]\.)'))
define TestHostCommand
  define Require/$(1)
	($(3)) >/dev/null 2>/dev/null
  endef

  $$(eval $$(call Require,$(1),$(2)))
endef

# 安装 host 程序到 staging 目录下
#
# 查找 $(1) 工具是否存在并依次执行检查命令, 如果通过, 则将 $(1) 指定的程序链接到 $(STAGING_DIR_HOST)/bin/ 目录下
# 多个条件有一个符合即可
# 1: canonical name		定义的目标名
# 2: failure message		失败时打印的log
# 3+: candidates		检查命令
#
# 这里的规则命令稍微有点复杂, 这里列出一个简化版:
#   - 目标位置文件不存在时, 建立软连接, 并 exit 1
#   - 目标位置文件存在时, 检查可执行权限通过后 exit 0
# if [ -n $cmd ]; then \
#     bin="$(command -v "${cmd%% *}")";
#     if [ -x $bin ] && eval "$cmd" >/dev/null 2>/dev/null; then
#         case "$(ls -dl -- $(STAGING_DIR_HOST)/bin/$(strip $(1)))" in 
#             "-"* | *" -> $bin"* | *" -> "[!/]*)
#                 [-x "$(STAGING_DIR_HOST)/bin/$(strip $(1))" ] && exit 0
#                 ;;
#         esac
#         ln -sf "$bin" "$(STAGING_DIR_HOST)/bin/$(strip $(1))";
#         exit 1
#      fi
# fi
#
# Note: 命令 ls -dl 的输出范例为:
# lrwxrwxrwx 1 user group 7 Jan 1 12:34 symlink_name -> target_path
define SetupHostCommand
  define Require/$(1)
	mkdir -p "$(STAGING_DIR_HOST)/bin"; \
	for cmd in $(call QuoteHostCommand,$(3)) $(call QuoteHostCommand,$(4)) \
	           $(call QuoteHostCommand,$(5)) $(call QuoteHostCommand,$(6)) \
	           $(call QuoteHostCommand,$(7)) $(call QuoteHostCommand,$(8)) \
	           $(call QuoteHostCommand,$(9)) $(call QuoteHostCommand,$(10)) \
	           $(call QuoteHostCommand,$(11)) $(call QuoteHostCommand,$(12)); do \
		if [ -n "$$$$$$$$cmd" ]; then \
			bin="$$$$$$$$(command -v "$$$$$$$${cmd%% *}")"; \
			if [ -x "$$$$$$$$bin" ] && eval "$$$$$$$$cmd" >/dev/null 2>/dev/null; then \
				case "$$$$$$$$(ls -dl -- $(STAGING_DIR_HOST)/bin/$(strip $(1)))" in \
					"-"* | \
					*" -> $$$$$$$$bin"* | \
					*" -> "[!/]*) \
						[ -x "$(STAGING_DIR_HOST)/bin/$(strip $(1))" ] && exit 0 \
						;; \
				esac; \
				ln -sf "$$$$$$$$bin" "$(STAGING_DIR_HOST)/bin/$(strip $(1))"; \
				exit 1; \
			fi; \
		fi; \
	done; \
	exit 1
  endef

  $$(eval $$(call Require,$(1),$(if $(2),$(2),Missing $(1) command)))
endef
