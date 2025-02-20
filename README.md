# 概要

本项目基于 openwrt 24.10 进行构建框架的分析

```shell
git clone git://git.openwrt.org/openwrt/openwrt.git
git reset v24.10.0 --hard
```

# 目标人群

- 希望能深入研究 openwrt 的构建流程的开发者

- 希望通过项目提升 Makefile 分析调试能力

# 目录及文件说明

| 目录     | 描述                                                         |
| -------- | ------------------------------------------------------------ |
| docs/    | 相关文档                                                     |
| include/ | 其他辅助 Makefile 的存放位置                                 |
| Makefile | 主 Makefile 入口                                             |
| package/ | 定义 openwrt 各类软件包构建, 安装方法                        |
| rules.mk | 定义 Makefile 的通用规则, 通用变量等, 一般为全局使用才会放到此处 |
| scripts/ | 存放各类脚本                                                 |
| target/  | 各种目标架构平台的构建方法                                   |

# 常用 Makefile 目标


| 目标        | 描述                     |
| --------- | ---------------------- |
| distclean | 彻底清理生成的文件, 比 clean 更彻底 |


# 使用 docker 部署构建环境

```shell
docker buildx build -t "mini_openwrt_build" -f Dockerfile .
```
# 构建流程分析

[构建主流程分析](./docs/构建主流程分析.md)
