# makefile 调试技巧

## 1. 使用 make 的调试选项

### 1.1. --justprint (-n)

该选项应该抑制所有命令执行。虽然这在某种意义上是正确的，但实际上，你必须小心。虽然 make 不会执行命令脚本，但它将计算在立即上下文中发生的 shell 函数调用。

### 1.2. --print-database (-p)

打印内部数据库

### 1.3. --debug

如果将调试选项指定为 --debug，则使用基本调试。如果调试选项为 -d，则使用 all。要选择其他选项的组合，使用逗号分隔的列表 --debug=option1,option2，其中选项可以是以下单词之一 (实际上，make 只看第一个字母)

- bisic
- verbose
- implicit
- jobs
- all

```shell
make --trace xxx #展开xxx目标代码的执行过程；
make --debug xxx #展开整个make解析和执行xxx的过程；
```

## 2. 使用 makefile 打印函数

```shell
$(info ...)    #不打印当前makefile名和行号
$(warning ...) #不中断makefile的执行，打印信息，并打印当前makefile文件名和行号
$(error ...)   #含warning的功能，同时会中断makefile的执行并退出
```

## 3. 使用 shell 手动执行子流程中的 make

对于编译架构中会嵌套多层的 make, 而这些 make 会读取当时的环境变量, 如果缺少这些环境变量就算获取到了编译命令, 直接手动执行也会出各种问题, 故可以在makefile中在指定位置调用shell来打断makefile的执行, 从而获得环境的控制权

## 4. remake 调试器

调试工具可使用 remake
