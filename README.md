基于 openwrt 24.10 进行分析

```shell
git clone git://git.openwrt.org/openwrt/openwrt.git
git reset v24.10.0 --hard
```

# 使用 docker 部署构建环境

```shell
docker buildx build -t "mini_openwrt_build" -f Dockerfile .
```
