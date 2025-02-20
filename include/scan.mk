# $(_SINGLE)$(NO_TRACE_MAKE) -j1 -r -s -f include/scan.mk SCAN_TARGET="packageinfo" SCAN_DIR="package" SCAN_NAME="package" SCAN_DEPTH=5 SCAN_EXTRA=""
# $(_SINGLE)$(NO_TRACE_MAKE) -j1 -r -s -f include/scan.mk SCAN_TARGET="targetinfo" SCAN_DIR="target/linux" SCAN_NAME="target" SCAN_DEPTH=3 SCAN_EXTRA="" SCAN_MAKEOPTS="TARGET_BUILD=1"
 
include $(TOPDIR)/include/verbose.mk
include $(TOPDIR)/rules.mk
TMP_DIR:=$(TOPDIR)/tmp

all: $(TMP_DIR)/.$(SCAN_TARGET)

SCAN_TARGET ?= packageinfo
SCAN_NAME ?= package
SCAN_DIR ?= package
TARGET_STAMP:=$(TMP_DIR)/info/.files-$(SCAN_TARGET).stamp
FILELIST:=$(TMP_DIR)/info/.files-$(SCAN_TARGET)-$(SCAN_COOKIE)
OVERRIDELIST:=$(TMP_DIR)/info/.overrides-$(SCAN_TARGET)-$(SCAN_COOKIE)

export ORIG_PATH:=$(if $(ORIG_PATH),$(ORIG_PATH),$(PATH))
export PATH:=$(STAGING_DIR_HOST)/bin:$(PATH)

define feedname
$(if $(patsubst feeds/%,,$(1)),,$(word 2,$(subst /, ,$(1))))
endef

ifeq ($(SCAN_NAME),target)
  SCAN_DEPS=image/Makefile profiles/*.mk $(TOPDIR)/include/kernel*.mk $(TOPDIR)/include/target.mk image/*.mk
else
  SCAN_DEPS=$(TOPDIR)/include/package*.mk
ifneq ($(call feedname,$(SCAN_DIR)),)
  SCAN_DEPS += $(TOPDIR)/feeds/$(call feedname,$(SCAN_DIR))/*.mk
endif
endif

ifeq ($(IS_TTY),1)
  ifneq ($(strip $(NO_COLOR)),1)
    define progress
	printf "\033[M\r$(1)" >&2;
    endef
  else
    define progress
	printf "\r$(1)" >&2;
    endef
  endif
else
  define progress
	:;
  endef
endif

# 生成一个目标, 调用 package 的 makefile 生成指定 package 的信息文件
# 并将这个目标作为 $(TMP_DIR)/.$(SCAN_TARGET) 依赖
# 1: 表示包的名称
# 2: 表示包的目录
# 3: (可选) 表示将会覆盖的 package
#
# example:
# .rw-r--r--@ 1.6k hide_liao 18 Aug  2021 tmp/info/.packageinfo-system_uci
# .rw-r--r--@  424 hide_liao 18 Aug  2021 tmp/info/.packageinfo-system_urandom-seed
# .rw-r--r--@ 1.1k hide_liao 18 Aug  2021 tmp/info/.packageinfo-system_urngd
# .rw-r--r--@  568 hide_liao 18 Aug  2021 tmp/info/.packageinfo-system_usign
# .rw-r--r--@  610 hide_liao 18 Aug  2021 tmp/info/.packageinfo-system_zram-swap
define PackageDir
  $(TMP_DIR)/.$(SCAN_TARGET): $(TMP_DIR)/info/.$(SCAN_TARGET)-$(1)
  $(TMP_DIR)/info/.$(SCAN_TARGET)-$(1): $(SCAN_DIR)/$(2)/Makefile $(foreach DEP,$(DEPS_$(SCAN_DIR)/$(2)/Makefile) $(SCAN_DEPS),$(wildcard $(if $(filter /%,$(DEP)),$(DEP),$(SCAN_DIR)/$(2)/$(DEP))))
	{ \
		$$(call progress,Collecting $(SCAN_NAME) info: $(SCAN_DIR)/$(2)) \
		echo Source-Makefile: $(SCAN_DIR)/$(2)/Makefile; \
		$(if $(3),echo Override: $(3),true); \
		$(if $(findstring c,$(OPENWRT_VERBOSE)),$(MAKE),$(NO_TRACE_MAKE) --no-print-dir) -r DUMP=1 FEED="$(call feedname,$(2))" -C $(SCAN_DIR)/$(2) $(SCAN_MAKEOPTS) \
			$(if $(findstring c,$(OPENWRT_VERBOSE)),,2>/dev/null) || { \
			mkdir -p "$(TOPDIR)/logs/$(SCAN_DIR)/$(2)"; \
			$(NO_TRACE_MAKE) --no-print-dir -r DUMP=1 FEED="$(call feedname,$(2))" -C $(SCAN_DIR)/$(2) $(SCAN_MAKEOPTS) > $(TOPDIR)/logs/$(SCAN_DIR)/$(2)/dump.txt 2>&1; \
			$$(call progress,ERROR: please fix $(SCAN_DIR)/$(2)/Makefile - see logs/$(SCAN_DIR)/$(2)/dump.txt for details\n) \
			rm -f $$@; \
		}; \
		echo; \
	} > $$@.tmp
	mv $$@.tmp $$@
endef

# 这个 override 文件记录有哪些 package 在 feed 中又提供了相同的包, 被覆盖了
#
# example:
# .rw-r--r--@ 12 hide_liao 18 Aug  2021 tmp/info/.overrides-packageinfo-24774
$(OVERRIDELIST):
	rm -f $(TMP_DIR)/info/.overrides-$(SCAN_TARGET)-*
	touch $@

ifeq ($(SCAN_NAME),target)
  GREP_STRING=BuildTarget
else
  GREP_STRING=(Build/DefaultTargets|BuildPackage|KernelPackage)
endif

# 这个文件记录了这个目录下所有 $(SCAN_TARGET) 的名称
#
# example:
# .rw-r--r--@  41k hide_liao 18 Aug  2021 tmp/info/.files-packageinfo-24774
$(FILELIST): $(OVERRIDELIST)
	rm -f $(TMP_DIR)/info/.files-$(SCAN_TARGET)-*
	find -L $(SCAN_DIR) -mindepth 1 $(if $(SCAN_DEPTH),-maxdepth $(SCAN_DEPTH)) $(SCAN_EXTRA) -name Makefile | xargs grep -aHE 'call $(GREP_STRING)' | sed -e 's#^$(SCAN_DIR)/##' -e 's#/Makefile:.*##' | uniq | awk -v of=$(OVERRIDELIST) -f include/scan.awk > $@

# 进入当前 makefile 首先会处理这个 makefile target 的规则, 生成一个用于生成 package target 的 makefile
# 如果 package 的 makefile 中 定义了 SCAN_DEPS 变量
# 会生成类似的行在makefile中
# DEPS_package/firmware/linux-firmware/Makefile=*.mk
# DEPS_package/kernel/linux/Makefile=modules/*.mk $(TOPDIR)/target/linux/*/modules.mk $(TOPDIR)/include/netfilter.mk
#
# example:
# .rw-r--r--@ 130k hide_liao 18 Aug  2021 tmp/info/.files-packageinfo.mk
$(TMP_DIR)/info/.files-$(SCAN_TARGET).mk: $(FILELIST)
	( \
		cat $< | awk '{print "$(SCAN_DIR)/" $$0 "/Makefile" }' | xargs grep -HE '^ *SCAN_DEPS *= *' | awk -F: '{ gsub(/^.*DEPS *= */, "", $$2); print "DEPS_" $$1 "=" $$2 }'; \
		awk -F/ -v deps="$$DEPS" -v of="$(OVERRIDELIST)" ' \
		BEGIN { \
			while (getline < (of)) \
				override[$$NF]=$$0; \
			close(of) \
		} \
		{ \
			info=$$0; \
			gsub(/\//, "_", info); \
			dir=$$0; \
			pkg=""; \
			if($$NF in override) \
				pkg=override[$$NF]; \
			print "$$(eval $$(call PackageDir," info "," dir "," pkg "))"; \
		} ' < $<; \
		true; \
	) > $@.tmp
	mv $@.tmp $@

-include $(TMP_DIR)/info/.files-$(SCAN_TARGET).mk

# 创建文件记录所有的 $(SCAN_TARGET), 即 package 或 target
#   tmp/info/.files-$(SCAN_TARGET)-$(SCAN_COOKIE)
#   tmp/info/.overrides-$(SCAN_TARGET)-$(SCAN_COOKIE)
# 创建印章文件(文件内容是空白的), 表示所有 $(SCAN_TARGET) 信息已经收集完毕
#   tmp/info/.files-$(SCAN_TARGET).stamp
#   tmp/info/.files-$(SCAN_TARGET).stamp.$MD5SUM
#
# example: 
# .rw-r--r--@  41k hide_liao 18 Aug  2021 tmp/info/.files-packageinfo-24774
# .rw-r--r--@    0 hide_liao  3 Aug  2021 tmp/info/.files-packageinfo.stamp
# .rw-r--r--@    0 hide_liao  3 Aug  2021 tmp/info/.files-packageinfo.stamp.dbeef90fea0fd7e6f34d09feb5db72f4
# .rw-r--r--@   12 hide_liao 18 Aug  2021 tmp/info/.overrides-packageinfo-24774
$(TARGET_STAMP)::
	+( \
		$(NO_TRACE_MAKE) $(FILELIST); \
		MD5SUM=$$(cat $(FILELIST) $(OVERRIDELIST) | $(MKHASH) md5 | awk '{print $$1}'); \
		[ -f "$@.$$MD5SUM" ] || { \
			rm -f $@.*; \
			touch $@.$$MD5SUM; \
			touch $@; \
		} \
	)

#
# 将 tmp/info/.$(SCAN_TARGET)-* 每一个 package 信息 merge 到 tmp/.$(SCAN_TARGET) 中, 如 tmp/.packageinfo
# 
# 这些 package 信息文件是怎么生成的呢?
#  当前 makefile 执行时, 会先执行 $(TMP_DIR)/info/.files-$(SCAN_TARGET).mk 创建目标, $(TMP_DIR)/info/.files-$(SCAN_TARGET).mk 中会调用 PackageDir 宏最终生成这些 package 信息文件
#
# example:
# .rw-r--r--@ 1.6k collin 18 Aug  2021 tmp/info/.packageinfo-system_uci
# .rw-r--r--@  424 collin 18 Aug  2021 tmp/info/.packageinfo-system_urandom-seed
# .rw-r--r--@ 1.1k collin 18 Aug  2021 tmp/info/.packageinfo-system_urngd
# .rw-r--r--@  568 collin 18 Aug  2021 tmp/info/.packageinfo-system_usign
# .rw-r--r--@  610 collin 18 Aug  2021 tmp/info/.packageinfo-system_zram-swap
# .rw-r--r--@ 1.4M collin 18 Aug  2021 tmp/.packageinfo
$(TMP_DIR)/.$(SCAN_TARGET): $(TARGET_STAMP)
	$(call progress,Collecting $(SCAN_NAME) info: merging...)
	-cat $(FILELIST) | awk '{gsub(/\//, "_", $$0);print "$(TMP_DIR)/info/.$(SCAN_TARGET)-" $$0}' | xargs cat > $@ 2>/dev/null
	$(call progress,Collecting $(SCAN_NAME) info: done)
	echo

FORCE:
.PHONY: FORCE
.NOTPARALLEL:
