# MentoHUST-SYSU-Guide

### 2021年更新

`mentohust` 已有十余年历史，部分功能可能已经不可用于当前系统。

例如，OpenWrt 更新到较新版本后，`mentohust` 出现了[每隔数分钟掉线一次](images/disconnected.jpg)的异常情况，是否为普遍现象未明。

因此，强烈建议换用 [**minieap**](https://github.com/KumaTea/minieap)
(Forked from [updateing/minieap](https://github.com/updateing/minieap),
[OpenWrt package](https://github.com/KumaTea/openwrt-minieap),
[OpenWrt index](https://github.com/KumaTea/openwrt-packages)) 。

移植方式没有太多改变，十分简单，然而性能及稳定性大幅提升。

## [支持锐捷认证与IPv6的路由器配置指南：以K2P为例](./Guide.md)
这是主教程内容

## 其他 / Others
这是附加内容

* [MentoHUST-SYSU-OpenWrt 软件包](https://github.com/KumaTea/MentoHUST-SYSU-OpenWrt)
* [IPv6 中继模式配置（优于原NAT模式）](IPv6_Relay.md)
* [空间太小放不下mentohust二进制怎么办](./Compress_bin.md)
* [参考配置](./config)

## Changelog
* 2018年08月10日 第一版
* 2018年12月21日 小修改
* 2019年10月22日 第二版
* 2019年12月02日 小修改
* 2020年01月06日 增加内容
* 2020年05月11日 添加链接
* 2021年04月05日 Deprecation Warning
