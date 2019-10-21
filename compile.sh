sudo -i
apt install build-essential bison flex zlib1g-dev libncurses5-dev subversion quilt intltool ruby fastjar unzip gawk autogen autopoint ccache gettext libssl-dev xsltproc zip git

cd /home/kumatea
mkdir k2p
cd k2p

wget http://downloads.openwrt.org/releases/18.06.4/targets/ramips/mt7621/openwrt-sdk-18.06.4-ramips-mt7621_gcc-7.3.0_musl.Linux-x86_64.tar.xz -O sdk.tar.xz
tar -xJf sdk.tar.xz
mv openwrt-sdk-18.06.4-ramips-mt7621_gcc-7.3.0_musl.Linux-x86_64 sdk
rm sdk.tar.xz

wget https://www.tcpdump.org/release/libpcap-1.9.1.tar.gz -O libpcap.tar.gz
tar -xzf libpcap.tar.gz
mv libpcap-1.9.1 libpcap
rm libpcap.tar.gz

PATH=$PATH:/home/kumatea/k2p/sdk/staging_dir/toolchain-mipsel_24kc_gcc-7.3.0_musl/bin
export PATH
STAGING_DIR=/home/kumatea/k2p/sdk/staging_dir/toolchain-mipsel_24kc_gcc-7.3.0_musl
export STAGING_DIR
export CC=mipsel-openwrt-linux-gcc
export CPP=mipsel-openwrt-linux-cpp
export GCC=mipsel-openwrt-linux-gcc
export CXX=mipsel-openwrt-linux-g++
export RANLIB=mipsel-openwrt-linux-musl-ranlib
export ac_cv_linux_vers=2.6.24
export LDFLAGS="-static"
export CFLAGS="-Os -s"

cd /home/kumatea/k2p/libpcap
./configure --host=mipsel-linux --prefix=/home/kumatea/k2p/ --with-pcap=linux
make

cd /home/kumatea/k2p/mentohust
sh autogen.sh
./config.guess

./configure --build=x86_64-pc-linux-gnu --host=mipsel-linux   --disable-encodepass --disable-notify --with-pcap=/home/kumatea/k2p/libpcap/libpcap.a
make

md5sum /home/kumatea/k2p/mentohust/src/mentohust
