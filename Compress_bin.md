# 空间太小放不下mentohust二进制怎么办

## 思路：压缩
运行：
```shell script
cd /tmp
mkdir compress
cd compress

# upload your mentohust file here

tar -czf mentohust.gz mentohust

cp mentohust.gz /usr/bin
```
体积可以缩小为原来46%左右

启动项：
```shell script
# startup
cd /tmp
mkdir mentohust
cd mentohust

cp /usr/bin/mentohust.gz /tmp/mentohust
tar -xzf mentohust.gz
rm mentohust.gz
chmod 755 mentohust

/usr/bin/mentohust <*args>
```
