

| 文件                        | 描述                                                                              |
| --------------------------- | --------------------------------------------------------------------------------- |
| `include/debug.mk`          | 定义了打印调试的一些规则, 由 openwrt 框架内一些重要 makefile 调用, 比如 subdir.mk |
| `include/verbose.mk`        | 定义了打印规范和打印等级的设定相关规则, 如 `V=99`                                 |
| `include/prereq.mk`         | 定义了检查 openwrt 依赖与安装依赖的通用规则                                       |
| `include/prereq-build.mk`   | 定义了 openwrt 的依赖, 调用 `include/prereq.mk` 实现                              |
| `include/scan.mk`           | 定义了收集 openwrt 的 packge 与 target 信息的通用规则                             |
| `include/subdir.mk`         | 定义了 openwrt 如何从主 makefile 编译到子目录的规则, 这是非常非常重要的 makefile  |
| `include/package-defaults.mk` | 定义了 package 相关的默认行为, 如默认编译动作                                     |
