# IPv6 中继模式配置
NAT野蛮，Relay文明，，，

前提条件：
* 校园网 IPv6 不限制设备数量
* WAN口获取到后缀 `/64` 的IPv6地址

---

## 防火墙
**不用配置**

## 网关
**同NAT：**

`route -A inet6 add default gw [REDACTED]`

## 网络
### 接口

**全局网络选项** - `IPv6 ULA 前缀`

**不用配置**
### WAN6

* 协议 `DHCPv6`
* 请求 IPv6 地址 `try`
* 请求指定长度的 IPv6 前缀 `auto`
* **高级** - 使用内置的 IPv6 管理 **不选中**

### LAN

**一般配置** - 高级设置
* 使用内置的 IPv6 管理 **可选**

**DHCP 服务器** -  IPv6 设置

* 路由通告服务 `中继模式`
* DHCPv6 服务 `中继模式`
* NDP 代理 `中继模式`
