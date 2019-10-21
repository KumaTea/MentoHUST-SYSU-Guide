*前言：这篇教程希望给读者，特别是没有相关IT知识的读者，提供一个尽可能简单易读而详尽的路由器配置指南，且期盼与本文实际情况不相同的读者也可以得到一些启发。整个过程用到了许多前辈的技术成果，在此表达感谢。由于水平有限，可能* ***十分冗长*** *、有不少错误和疏漏，还请各位多多海涵。*
 
在校园网只有有线网络的限制下，满足手机平板等无线设备联网并享受校园网的各种优势应该是很多学生党的刚需。本文就以在SYSU的v4.90版本锐捷认证的校园网下，配置典型的**MT7621**芯片的路由器 (PHICOMM **K2P** A2
) 的实例，来说明这个过程。其他平台及芯片的读者，也可参考本文的通用方法。
尽管本文设计为可以按步骤直接从头至尾配置完成，但建议有相似需求的读者，可以先通读一遍教程，再动手。
![K2P定妆照](https://upload-images.jianshu.io/upload_images/13484287-4abc9f2a0b04eaa0.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* * *
# 准备工作
* 一只电脑和一只路由器
* 两坨网线
* 你的IPv6网关（说明见下）
* 有线连接设为“自动获取IP地址”
* **“刷入Breed”**步骤中的**k2p.sh**文件
* （建议）“上传MentoHUST到路由器”步骤的[WinSCP](https://winscp.net/eng/download.php)工具
* （建议）[恩山论坛](http://www.right.com.cn/forum)的账号
* Linux系统，推荐Ubuntu 16.04（说明见“锐捷认证与MentoHUST”章节）
* 一杯茶️
* 一个下午

![路由追踪](http://upload-images.jianshu.io/upload_images/13484287-20f56cc56e8e480c?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
使用“路由追踪” (Windows: tracert; Linux: traceroute) 命令，
可以方便的知道你的网关。
例如，在Windows下，请使用有线上网的方式，追踪一个IPv6地址，例如：
```cmd
tracert tv.byr.cn
```
然后记录第一条地址（应该以 2xxx: 开头，不应以 fe80: 开头；冒号很重要，要记全）即可。
* * *
# 锐捷认证与MentoHUST
**工具 / 步骤 / 参考文献 / 请先阅读：（排名不分先后）**
**1. [Mentohust V4版本的心得](https://codingstory.com.cn/mo-gai-mentohust-v4ban-ben-de-xin-de/)，作者是ShanQincheng；**（原网址已失效，且无WebArchive存档，[这里是无图版本](https://github.com/kkkeQAQ/mentohust_nwafu/blob/master/README.md)，谷歌图片可搜到少量缓存低清晰度图片）
**2. [Cross Compile [OpenWrt Wiki]](https://wiki.openwrt.org/doc/devel/crosscompile)，作者是OpenWrt官方；**
**3. [交叉编译mentohust实现锐捷认证共享上网](https://blog.csdn.net/warriorpaw/article/details/7990226)，作者是[warriorpaw](https://blog.csdn.net/warriorpaw)；**
**4. [mentohust v4版本编译及ipv6的配置教程](http://soundrain.net/2016/04/25/mentohust-v4%E7%89%88%E6%9C%AC%E7%BC%96%E8%AF%91%E5%8F%8Aipv6%E7%9A%84%E9%85%8D%E7%BD%AE/)，作者请见原页面；**
**5. ivechan的[mentohust的SYSU版本](https://github.com/ivechan/mentohust-SYSU)；Placya的[Fork的版本](https://github.com/Placya/mentohust-SYSU)**
**6. [mentohust加入v4支持](https://github.com/hyrathb/mentohust)，作者是hyrathb；**
**7. MentoHUST源码、交叉编译工具包、libpcap请见下文详述。**
**MentoHUST**，是由华中科技大学的**HustMoon**（一说liuqun ）开发的一款破解锐捷认证的软件。近十年来，MentoHUST经过原作者和众多贡献者的努力，已经逐步发展到可以破解锐捷v2, v3甚至v4认证了。本文中所采用的例子是v4.90版锐捷，也就是v3认证。
![MentoHUST是大学生的大救星 (](https://upload-images.jianshu.io/upload_images/13484287-2033c8f1bab06a94.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

MentoHUST一开始开发出来，只是适合于华中科技大学 (HUST)，需要再做修改才能适用于实际环境，而这个适配过程是十分痛苦的。笔者是外行，只能尝试大致的说明一下。

### 锐捷数据包的分析与MentoHUST的修改
对于分析与修改的问题，上面提到的[Mentohust V4版本的心得](https://codingstory.com.cn/mo-gai-mentohust-v4ban-ben-de-xin-de/)这篇文章已经写得十分详细和易于操作，我也成功通过该方法分析到了数据，自己水平有限就不造轮子了，大家看一看会很有帮助。
**分析心跳包这一步需要注意间隔，默认间隔是30s，但我校的间隔则是20s，故需要在后续步骤配置，请大家注意。**
但是在做到一半的时候，偶然看到了Placya的[mentohust的SYSU版本](https://github.com/Placya/mentohust-SYSU)，~~服从于人类懒的天性，~~于是就直接拿来用了。
有了修改好的文件之后，就可以进入下一步了。
向各位贡献者表达敬意。
### 交叉编译
我们知道，编程语言需要翻译为机器语言才能让机器理解并执行。而所谓[交叉编译](enwp.org/Cross_compiler)，就是在A机器上为B机器编译软件。
首先，为了编译MT76XX的可执行文件，我们需要一个Linux系统。为什么推荐Ubuntu呢？因为——Windows 10可以不装虚拟机就运行Ubuntu啊~（当然还有别的，但是Ubuntu比较适合新手）
![Windows的Linux子系统安装过程](https://upload-images.jianshu.io/upload_images/13484287-bbab43aae9b0adff.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![虚拟机是比较稳妥的选择](https://upload-images.jianshu.io/upload_images/13484287-1a542b5b1ee258cf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
至于为什么是16.04版，因为笔者在使用18.04编译时一直遭遇不明错误，而使用16.04两次就成功了。
要注意的是，Linux对大小写**敏感**，所以图方便改文件名的时候要特别小心。

1. 确保装好了Linux系统，打开你们头大或喜闻乐见的终端 (Terminal)
2. 到[OpenWrt的官网](http://downloads.openwrt.org)下载适用于你的路由器的芯片和系统的交叉编译工具包 (SDK)，比如我下载的是[这个版本的SDK](http://archive.openwrt.org/chaos_calmer/15.05.1/ramips/mt7621/OpenWrt-SDK-15.05.1-ramips-mt7621_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64.tar.bz2)。可以先改个文件名；解压```.tar.bz2```文件到```/home/xxx```**（xxx是你的用户名）**下：
```
tar jxvf SDK.tar.bz2
```
3. 下载libpcap，[戳我下载1.7.4版](http://www.tcpdump.org/release/libpcap-1.7.4.tar.gz),一样解压到```/home/xxx```下，注意命令不同了：
```
tar zxvf libpcap-1.7.4.tar.gz
```
4. 把前面做好的MentoHUST的文件夹放到```/home/xxx```下
![得到这三个文件](https://upload-images.jianshu.io/upload_images/13484287-3986c6870d89afe5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
5. 配置环境：
**首先把下面代码的“xxx”换成你所创建的账户名，并修改为你自定义的文件夹名，尤其是PATH=$PATH:和STAGING_DIR=这里**，再（建议逐行复制）运行下面的命令：
```
sudo -i
```
这一步需要输入密码，来以管理员身份进行下面步骤。**再次提醒要改路径！**
```
apt-get install build-essential bison flex zlib1g-dev libncurses5-dev subversion quilt intltool ruby fastjar unzip gawk autogen autopoint
PATH=$PATH:/home/xxx/SDK/staging_dir/toolchain-mipsel_1004kc+dsp_gcc-4.8-linaro_uClibc-0.9.33.2/bin
export PATH
STAGING_DIR=/home/xxx/SDK/staging_dir/toolchain-mipsel_1004kc+dsp_gcc-4.8-linaro_uClibc-0.9.33.2
export STAGING_DIR
export CC=mipsel-openwrt-linux-gcc  
export CPP=mipsel-openwrt-linux-cpp  
export GCC=mipsel-openwrt-linux-gcc  
export CXX=mipsel-openwrt-linux-g++  
export RANLIB=mipsel-openwrt-linux-uclibc-ranlib  
export ac_cv_linux_vers=2.6.24  
export LDFLAGS="-static"  
export CFLAGS="-Os -s"  
``` 
然后cd进入libpcap文件夹并执行命令，**同样要改路径**：
```
cd /home/xxx/libpcap-1.7.4
./configure --host=mipsel-linux --prefix=/home/xxx/work/ --with-pcap=linux
make
```
这里会滚一段代码，有所了解的同学能看到出错了，但是我们会发现目录里已经生成了我们需要的```libpcap.a```文件，根据黑猫白猫论，这次编译是成功的。
6. 重头戏——编译MentoHUST：
首先，要获取一下我们自己所在的平台：
```
cd /home/xxx/MentoHUST
sh autogen.sh
./config.guess
```
（说明一下，./config.guess这一步，只在OpenWrt的官方文档中出现，在笔者看到的教程中并未见到。加上去的理由是，不通过这一步一直编译失败，加上应该能规避一些问题）
这时终端会输出你的平台：
![平台代码](https://upload-images.jianshu.io/upload_images/13484287-209402681d1ab6a6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

例如我的虚拟机是```x86_64-pc-linux-uclibc```，复制一下。然后把复制的内容替换到下面的```<替换>```，再执行：
```
./configure --build=<替换> --host=mipsel-linux   --disable-encodepass --disable-notify --with-pcap=/home/xxx/libpcap-1.7.4/libpcap.a
make
```
这个时候，你就可以进入```/home/xxx/MentoHUST/src```，获取你的```MentoHUST```文件了。
![文件如图，大小仅供参考，我编译的大小都不一样，能用就行](https://upload-images.jianshu.io/upload_images/13484287-ff85f51f18b52018.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

PC端工作大功告成，喝杯昏睡红茶庆祝一下。
* * *
# 刷入Breed
**工具 / 步骤 / 参考文献 / 请先阅读：（排名不分先后）**
**1. [[k2p] K2/K2P/K3/K3C 新版固件 Telnet 激活工具
](http://www.right.com.cn/forum/thread-221578-1-1.html)，作者是[phitools](http://www.right.com.cn/forum/space-uid-389408.html)；**
**2. [[k2p] 【2018-06-19】斐讯K2P MTK官方固件定制版，加adb、S-S R、KMS等【V1.6】](http://www.right.com.cn/forum/thread-221578-1-1.html)，作者是[abccba94](http://www.right.com.cn/forum/space-uid-140971.html)。**
* 由于路由器买来之后一般附带的是官方固件，我们需要把它更换为第三方的功能更全的固件，才能进行下一步的操作。
* 刷入固件前，一般需要刷入Breed，可以近似的理解为解锁BootLoader后刷入的Recovery，还是TWRP这一类的。

1. 在[[k2p] K2/K2P/K3/K3C 新版固件 Telnet 激活工具
](http://www.right.com.cn/forum/thread-221578-1-1.html)处确认适用的版本，如适合则下载```RoutAckProV1B2.rar```并解压。
2. 确保开启Telnet：![Windows下开启Telnet](https://upload-images.jianshu.io/upload_images/13484287-3506cb773ec3e156.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

3.仅连接电脑的有线网口与路由器的LAN口，不连接WAN口，然后路由器上电启动。
4. **打开```RoutAckProV1B2.exe```，当路由器LED灯由红变为黄时，立即点击“打开Telnet”按钮。**等待出现成功信息，若不成功请再试一次。![错误示范](https://upload-images.jianshu.io/upload_images/13484287-7ee789b65a11b83b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
5. 成功打开Telnet后，连接到你的路由器，可以使用PuTTY等工具连接，也可以用命令提示符：
```cmd
telnet 192.168.2.1
```
6. 使你在准备步骤中下载的```k2p.sh```文件处于可访问状态。这个时候一般路由器不能上网，怎么解决大家见仁见智，我用的是开启ftp服务器的方式：![用es文件浏览器开启ftp服务器](https://upload-images.jianshu.io/upload_images/13484287-76016a6fc61b62a8.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
然后执行：
```
wget <你的k2p.sh地址> -O - |sh
```
来进行Breed刷写。出现“```upgrade ok! reboot...```”就成功了。
7. 然后进入Breed：
* 路由断电
* 按住Reset，通电
* 待LED颜色交替闪烁时放开
* 访问[http://192.168.1.1](http://192.168.1.1)，若能看到**“Breed Web 恢复控制台”**的蓝色大字标题，即为成功
![就是这个](https://upload-images.jianshu.io/upload_images/13484287-4aac807b18931b76.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
* * *
# 刷入OpenWrt
**工具 / 步骤 / 参考文献 / 请先阅读：**
**1. [[k2p] [2018-03-06] K2P openwrt chaos_calmer V1.7 正式版发布](http://www.right.com.cn/forum/thread-240730-1-1.html)，作者是[mleaf](http://www.right.com.cn/forum/space-uid-284724.html)；**
**2. mleaf的适用于K2P的OpenWrt固件1.7.2版（由于下载地址在原帖中为隐藏内容，故这里也不应当提供下载）**
* 一般来说，第三方固件在性能、功耗方面的表现都比原版的好。
* 一般来说，刷入Breed后，就不怕刷砖了。
* 经过笔者多次尝试，Padavan（又称老毛子）固件各方面都较适合家用，而为了支持锐捷和NAT6，则应该选择**OpenWrt**固件。仅供参考。

1. 上一章节进入Breed后，下载适用的OpenWrt固件，注意鉴别版本，且应为```.bin```文件。
2. （建议）在左边**“固件备份”**处，备份现有固件
3. （建议）在左边**“恢复出厂设置”**处，重置Config区
4. 在左边**“固件更新”**处，**仅点击**“固件”的“选择文件”按钮，选中下载的```.bin```文件，再点击下面的“上传”
5. 机器会开始刷机，这个时候可以喝茶了

注：进度条飙到150%不要怕，它会自己刷机重启；重启不了也不要怕，过五分钟断电上电就可以；我们可是有Breed的人 /滑稽
6. 欢迎来到OpenWrt
![mleaf的K2P的OpenWrt的1.7.2版](https://upload-images.jianshu.io/upload_images/13484287-3a6908d7f4210d49.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
**特别提醒，有的学校采用IP与MAC绑定的上网方式，如果后续锐捷认证步骤上不了网，可以尝试在路由配置里启用MAC地址克隆，复制电脑网卡地址和IP地址。**
* * *
# 上传MentoHUST到路由器
**工具 / 步骤 / 参考文献 / 请先阅读：**
**1. [锐捷、赛尔认证MentoHUST](http://wiki.ubuntu.org.cn/%E9%94%90%E6%8D%B7%E3%80%81%E8%B5%9B%E5%B0%94%E8%AE%A4%E8%AF%81MentoHUST)，作者是HustMoon；**
**2. （建议）[WinSCP](http://winscp.net)，[Windows或Linux下载链接](https://winscp.net/eng/download.php)**

编译完MentoHUST，安装好OpenWrt之后，我们就可以把它传输到路由器里运行了。喜欢命令行的同学可以使用Telnet或SSH，但这里用有图形界面，较易操作的WinSCP来说明。
1. 打开WinSCP后，请点击“新增站点”，再填写 "```SCP```" "```192.168.2.1```" "```22```" "```root```" "```<你设定的管理密码>```"，再点击“登录”按钮。
![WinSCP](https://upload-images.jianshu.io/upload_images/13484287-ee7ce35e96935f20.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
2. 进入后，左边定位到你的放置MentoHUST文件的文件夹，右边定位到```/usr/bin/```，然后选中文件，点击“上传”
![又截一张](https://upload-images.jianshu.io/upload_images/13484287-85ec3c659c52debd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
3. 这个时候接上WAN口网线，然后在**WebShell**里就可以运行了。进入[路由管理页面](http://192.168.2.1)，WebShell在**“系统”**下。网卡代码（eth）在OpenWrt可以查到。
![Webshell的位置与MentoHUST运行示例](https://upload-images.jianshu.io/upload_images/13484287-38b54a25db8397b5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
运行```/usr/bin/mentohust -h```可以获取帮助。
>用法:	/usr/bin/mentohust [-选项][参数]
选项:	-h 显示本帮助信息
	-k -k(退出程序) 其他(重启程序)
	-w 保存参数到配置文件
	-u 用户名
	-p 密码
	-n 网卡名
	-i IP[默认本机IP]
	-m 子网掩码[默认本机掩码]
	-g 网关[默认0.0.0.0]
	-s DNS[默认0.0.0.0]
	-o Ping主机[默认0.0.0.0，表示关闭该功能]
	-t 认证超时(秒)[默认8]
	-e 心跳间隔(秒)[默认30]
	-r 失败等待(秒)[默认15]
	-l 允许失败次数[0表示无限制，默认8]
	-a 组播地址: 0(标准) 1(锐捷) 2(赛尔) [默认0]
	-d DHCP方式: 0(不使用) 1(二次认证) 2(认证后) 3(认证前) [默认0]
	-b 是否后台运行: 0(否) 1(是，关闭输出) 2(是，保留输出) 3(是，输出到文件) [默认0]
	-v 客户端版本号[默认0.00表示兼容xrgsu]
	-f 自定义数据文件[默认不使用]
	-c DHCP脚本[默认dhclient]
	-q 显示SuConfig.dat的内容(如-q/path/SuConfig.dat)

不是全部参数都需要填，我的配置如下：
```/usr/bin/mentohust -u<账号，中间不空格> -p<密码> -neth1 -e20 -b3```
修改为你的配置，再填入WebShell运行，可能没有输出反馈，但可以尝试能否上网，如果可以就成功了。**特别提醒，如果校园网IPv4不是自动获取IP地址，这里就需要配置固定IP，否则无法上网。**
4. 为了让路由器断电或重启后还能自动启动认证，我们可以设置其开机启动。
进入**“系统”**下的“启动项”，拉到最底的“本地启动脚本”，**在```exit 0```上面**添加你的代码即可。
```
# mentohust （这是示例）
/usr/bin/mentohust -u<账号，中间不空格> -p<密码> -neth1 -e20 -b3
```
# 路由器IPv6的配置
**1. [在OpenWrt上配置原生IPv6 NAT](https://tang.su/2017/03/openwrt-ipv6-nat/)，作者是[Cod1ng](https://blog.csdn.net/Cod1ng)；**

>“其实地上本没有路，走的人多了，也便成了路。” ——鲁迅

IPv6因为其**几乎**无尽的地址，本身不需要[网络地址转换 (NAT)](http://zhwp.org/网络地址转换) 这种东西。然而，由于校园网IPv6的局限和迟缓的发展（历史的行程），大学生们仍然需要IPv6 NAT来满足探索世界的需求（人民的选择）。所幸，OpenWrt是支持NAT6的（Padavan则测试失败了），所以下面就尝试讲述一下如何配置。
1. 进入[路由管理页面](http://192.168.2.1)，到**“系统”**下的“软件包”检查是否有```ip6tables```和```kmod-ipt-nat6```，没有就安装一下。
```
opkg update
opkg install ip6tables
opkg install kmod-ipt-nat6
```
2. 使用WinSCP进入```/etc/config/```目录。
* 修改**network**文件：打开```network```文件，找到```config interface 'lan'```这一栏，在下面加入（#号那一行不用）：
```
# 前面空空的不是空格是Tab键
	option ip6addr 'fc00:100:100:1::1/64'
```
这是确定了分配的IPv6地址范围。
![示例](https://upload-images.jianshu.io/upload_images/13484287-34f9c7ae12f1d4d0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 修改**dhcp**文件：打开```dhcp```文件，找到```config dhcp 'lan'```这一栏，比对下面的代码，有缺失的、不同的就请加上：
```
# 前面空空的不是空格是Tab键
	option interface 'lan'
	option start '100'
	option limit '100'
	option leasetime '12h'
	option dhcpv6 'server'
	option ra 'server'
	option ra_management '1'
	option ra_default '1'
```
3. 进入[路由管理页面](http://192.168.2.1)，进入**“网络”**下的“防火墙”，再进入“自定义规则”选项卡，添加这些内容（#号那一行不用）：
```
# 让IPv6顺利通过路由器防火墙
ip6tables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
ip6tables -F
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
```
4. 手动添加网关。这一步用到了最前面获取的网关。直接在WebShell输入下方命令即可上IPv6了，但我推荐输到启动项里（#号那一行不用）：
```
# ipv6
sleep 30s
route -A inet6 add default gw <你的网关>
```
```sleep```就是等待，作用是适配一些获取IPv6地址比较慢的校园网（SYSU就是这种情况，故加上）
![启动项全家福](https://upload-images.jianshu.io/upload_images/13484287-fccddfc6222029cd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

重启路由器，大功告成！
* * *
# EOF
希望大家不要经历太多失败吧_(:з」∠) _
对本文参考的各位前辈表达笔者衷心的感谢。

我的环境：
>OS: Windows 10 Pro 1803
>VM: Ubuntu 16.04 LTS
>Router: PhiComm K2P A2 (Silver)
>Firmware: OpenWrt Chaos Calmer 15.05.1
>Libpcap: v1.7.4
>锐捷: v4.90
>MentoHUST: v0.3.1
>IPv4: China Unicomm
>IPv6: CERNET2 / Native

资源（只有跟我锐捷和路由芯片相同的才能拿去哦，否则请慎重使用）：
MentoHUST：[百度网盘](https://pan.baidu.com/s/1UO8HX4x3k4iIJuv40ENV_Q)

2018年8月10日第一版
2018年12月21日小修改