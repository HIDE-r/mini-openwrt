# 检查依赖时为什么有一些显示ok有一些显示update?

```shell
Checking 'true'... ok.
Checking 'false'... ok.
Checking 'working-make'... ok.
Checking 'case-sensitive-fs'... ok.
Checking 'proper-umask'... ok.
Checking 'gcc'... updated.
Checking 'working-gcc'... ok.
Checking 'g++'... updated.
Checking 'working-g++'... ok.
Checking 'ncurses.h'... ok.
Checking 'git'... updated.
Checking 'rsync'... updated.
Checking 'perl-data-dumper'... ok.
Checking 'perl-findbin'... ok.
Checking 'perl-file-copy'... ok.
Checking 'perl-file-compare'... ok.
Checking 'perl-thread-queue'... ok.
Checking 'perl-ipc-cmd'... ok.
Checking 'tar'... updated.
Checking 'find'... updated.
Checking 'bash'... updated.
Checking 'xargs'... updated.
Checking 'patch'... updated.
Checking 'diff'... updated.
Checking 'cp'... updated.
Checking 'seq'... updated.
Checking 'awk'... updated.
Checking 'grep'... updated.
Checking 'egrep'... updated.
Checking 'getopt'... updated.
Checking 'realpath'... updated.
Checking 'stat'... updated.
Checking 'gzip'... updated.
Checking 'unzip'... updated.
Checking 'bzip2'... updated.
Checking 'wget'... updated.
Checking 'install'... updated.
Checking 'perl'... updated.
Checking 'python'... updated.
Checking 'python3'... updated.
Checking 'python3-distutils'... ok.
Checking 'python3-stdlib'... ok.
Checking 'file'... updated.
Checking 'which'... updated.
Checking 'argp.h'... ok.
Checking 'fts.h'... ok.
Checking 'obstack.h'... ok.
Checking 'libintl.h'... ok.
Checking 'ldconfig-stub'... ok.
Collecting package info: done
```

这是因为这个过程除了检查依赖, 还会调用 `include/prereq.mk` 中的 `SetupHostCommand` 对当前主机的部分可执行程序软链接到staging目录下, 作为主机工具使用. 使用 `SetupHostCommand` 建立的主机工具成功时会打印 updated.

从 Makefile 分析, 比如 tar, 构建 `prereq` 时会根据依赖调用到 `prereq-tar`, 从而打印 checking 'tar' ...

```makefile
# include/prereq.mk

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
```

进入第一次检查, 会看到 SetupHostCommand 建立软链接时会以 exit 1 退出

```
		if $(NO_TRACE_MAKE) -f $(firstword $(MAKEFILE_LIST)) check-$(1) PATH="$(ORIG_PATH)" >/dev/null 2>/dev/null; then \
			echo 'ok.'; \
```


进入第二次检查, 这时成功以 exit 0 退出, 故打印 updated.
```
		elif $(NO_TRACE_MAKE) -f $(firstword $(MAKEFILE_LIST)) check-$(1) PATH="$(ORIG_PATH)" >/dev/null 2>/dev/null; then \
			echo 'updated.'; \
```


