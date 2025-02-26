# 概要

本项目基于 openwrt 24.10 进行构建框架的分析

```shell
git clone git://git.openwrt.org/openwrt/openwrt.git
git reset v24.10.0 --hard
```

# 目录及文件说明

| 目录       | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| docker/    | 容器相关文件                                                 |
| docs/      | 当前项目的文档                                               |
| include/   | 其他辅助类 Makefile 的存放位置                               |
| LICENSES/  | 存放各类许可证                                               |
| Makefile   | 主 Makefile 入口                                             |
| package/   | 定义 openwrt 各类软件包构建方法                              |
| rules.mk   | 定义 Makefile 的通用规则, 通用变量等, 一般为全局使用才会放到此处 |
| scripts/   | 存放各类脚本                                                 |
| target/    | 各种目标架构平台的构建方法                                   |
| toolchain/ | 各个交叉编译软件包的构建方法                                 |
| tools/     | 各个宿主机软件包的构建方法                                   |

# 常用 Makefile 目标


| 目标      | 描述                                |
| --------- | ----------------------------------- |
| distclean | 清理所有生成的文件, 比 clean 更彻底 |
| clean     | 清理当前指定架构生成的文件          |


# 使用 docker 部署构建环境

```shell
cd docker
docker buildx build -t "mini_openwrt_build" -f Dockerfile .
```
# 相关文档

[构建主流程分析](./docs/构建主流程分析.md)

其他文档: [docs](./docs)



<a href="https://www.buymeacoffee.com/LKangN" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
