# 360V6 (RE-CS-02) OpenWRT NSS 精简固件编译工程

## 硬件规格

| 项目 | 参数 |
|------|------|
| 设备型号 | 360安全路由V6 (RE-CS-02) |
| SoC | Qualcomm IPQ6000 (4核 Cortex-A53 @ 1.5GHz) |
| NPU | NSS网络加速引擎 |
| Flash | 128MB NAND |
| RAM | **1GB** (原装512MB，已升级) |
| WiFi | QCN5022 (2.4G) + QCN5052 (5G) |
| 网口 | 1×WAN + 3×LAN (千兆) |
| USB | 1×USB 2.0 |
| OpenWrt目标 | qualcommax / ipq60xx |
| 设备名 | qihoo_360v6 |

---

## 固件方案

### 源码基础

基于 **laipeng668/openwrt-6.x** 的 `main-nss` 分支编译：
- **Linux 6.12 内核**，完整NSS硬件加速支持
- 源自ImmortalWrt/LibWrt，包含全功能NSS驱动（kmod-qca-nss-*）
- NSS固件版本：v11.4
- ath11k WiFi内存Profile：**1G**（DTS已原生支持1GB物理内存，无需额外补丁）

### 预装软件包

| 类别 | 软件包 |
|------|--------|
| **管理界面** | LuCI全套 + 状态页 + Aurora主题（简体中文） |
| **NSS加速** | 全套qca-nss驱动 + ECM连接管理器 + NSS Qdisc |
| **科学上网** | **OpenClash**（最新版，自带TUN/TProxy依赖） |
| **网络功能** | UPnP、DDNS、WireGuard VPN、NSS版SQM流量整形 |
| **系统工具** | bash、htop、nano、openssh-sftp-server、ttyd终端 |
| **存储支持** | USB存储、ext4/vfat文件系统 |
| **交换分区** | zram-swap（LZ4压缩） |

### 已删除的软件包

以下参考固件中默认包含但日常使用频率低的包已全部移除：

- **代理类**：PassWall全套（与OpenClash功能重复）
- **下载类**：aria2、ariang
- **KMS激活**：vlmcsd
- **内网穿透**：frps、frpc
- **磁盘工具**：diskman、hd-idle、smartmontools
- **存储共享**：samba4
- **安全增强**：banip、acme、arpbind
- **硬件相关**：usb-printer、athena-led
- **应用过滤**：OpenAppFilter (OAF)
- **系统管理**：autoreboot、watchcat、wifischedule、cpufreq、wol
- **推送类**：wechatpush、3cat
- **DNS优化**：smartdns
- **组网类**：zerotier
- **其他**：lucky、openlist2、gecoosac

---

## 编译步骤（GitHub Actions云编译）

### 前置准备

1. 注册/登录 GitHub 账号
2. **Fork 本仓库**到你自己的账号

### 步骤一：配置仓库权限

1. 进入你Fork后的仓库
2. 点击 **Settings** → **Actions** → **General**
3. 下滑到 **Workflow permissions**，选择 **Read and write permissions**
4. 点击 **Save**

### 步骤二：触发编译

1. 点击 **Actions** 标签
2. 左侧选择 **360V6 OpenWRT NSS Firmware Build**
3. 点击右侧 **Run workflow** 按钮
4. 确认分支为 `main`，点击绿色 **Run workflow**

### 步骤三：等待编译

- 编译预计耗时：**1~2小时**（首次编译，后续有ccache缓存会更快）
- 可在Actions页面查看实时日志
- 编译完成后，在该次运行页面底部 **Artifacts** 区下载固件

### 步骤四：获取固件

下载 `360V6-NSS-OpenClash-firmware` 压缩包，内含：
- `openwrt-qualcommax-ipq60xx-qihoo_360v6-squashfs-nand-sysupgrade.bin` — 系统升级用
- `openwrt-qualcommax-ipq60xx-qihoo_360v6-squashfs-nand-factory.ubi` — 首次刷入用（如存在）
- `.manifest` — 预装包清单

---

## 刷机方法

### 方式A：sysupgrade升级（已在OpenWRT下）

通过LuCI界面：**系统 → 备份/升级 → 刷写新的固件**
- 跨大版本升级建议**不保留配置**
- 上传 `sysupgrade.bin`

### 方式B：U-Boot刷入（救砖/首次刷机）

通过串口连接U-Boot，使用TFTP刷入 `factory.ubi`。

---

## 刷后初始配置

### 登录管理界面

- 地址：`http://192.168.1.1`
- 用户：`root`
- 密码：无（首次登录设置）

### 验证1GB内存

SSH登录后执行：
```sh
free -m
```
应看到约 **1000MB+** total内存。本固件DTS已原生支持1GB，无需额外补丁。如果仍只识别到约450MB，说明物理内存升级有问题，请检查焊接。

### 验证NSS加速

SSH执行：
```sh
# 检查NSS驱动
lsmod | grep nss

# 查看NSS统计（跑测速后对比）
cat /sys/kernel/debug/qca-nss-drv/stats
```
**判断标准**：跑满速时CPU占用率应 **<20%**（4核平均），rx_bytes/tx_bytes持续增长。

> 注意：NSS加速普通转发流量；Clash代理流量因加解密必须经过CPU，不走NSS，这是正常现象。

### OpenClash初始配置

1. 进入 **服务 → OpenClash**
2. 首次启动提示安装内核，点击自动下载（国内网络慢可手动下载mihomo内核放到 `/etc/openclash/core/clash_meta`）
3. 配置订阅或手动上传配置
4. 运行模式建议 **Fake-IP**
5. 保存并启动

---

## 文件结构

```
360V6-OpenWRT-NSS/
├── .github/workflows/
│   └── build-openwrt.yml    # GitHub Actions编译工作流
├── configs/
│   ├── IPQ60XX.config       # 目标平台与设备配置
│   └── General.config       # 预装软件包列表
├── scripts/
│   └── Roc-script.sh        # 编译前自定义脚本
└── README.md                # 本说明文档
```

---

## 常见问题

### Q1: 编译失败，提示找不到qihoo_360v6设备

A: 源码树设备名可能不同。在Actions日志中搜索 `TARGET_DEVICE`，或修改 `configs/IPQ60XX.config` 中的设备名为 `jdcloud_re-cs-02`（京东云亚瑟，硬件与360V6相同）。

### Q2: NSS加速不生效

A:
1. 确认 `lsmod | grep nss` 有输出
2. `dmesg | grep nss` 查看错误
3. 确认防火墙关闭了软件flow offload（NSS自己接管）
4. 检查编译日志中的 `ERROR: package` 行

### Q3: 1GB内存只识别到512MB

A: 本固件DTS已原生支持1GB，无需补丁。如识别不正确，请检查：
1. 物理内存升级焊接是否正常
2. `dmesg | grep Memory` 查看内核报告的内存大小
3. 个别情况下可在U-Boot中执行 `setenv bootargs mem=1024M && saveenv && reset` 强制指定

### Q4: OpenClash内核下载失败

A: OpenClash内核在GitHub Release中，国内网络可能需要代理。手动下载mihomo内核放到 `/etc/openclash/core/clash_meta`。

---

## 参考链接

- [xsj520/360v6 参考固件](https://github.com/xsj520/360v6)
- [laipeng668/openwrt-6.x NSS源码](https://github.com/laipeng668/openwrt-6.x/tree/main-nss)
- [OpenClash官方仓库](https://github.com/vernesong/OpenClash)
- [Aurora主题](https://github.com/eamonxg/luci-theme-aurora)
