export UBOOT=/tmp/uboot
export KFS=/tmp/fs
export BACKUP_OVERLAY=/tmp/sysupgrade.tgz
export BOOTLOADER=Bootloader
export FIRMWARE=firmware
export OVERLAY=rootfs_data
export UPGRADE_LOG=/tmp/upgrade.log
BACKUP_LIST=/tmp/sysupgrade.conffiles
RAM_ROOT=/tmp/root
OWINFO_FILE=/tmp/ow_info
FWINFO_FILE=/tmp/fw_info

ldd() { LD_TRACE_LOADED_OBJECTS=1 $*; }
libs() { ldd $* | awk '{print $3}'; }

install_file() { # <file> [ <file> ... ]
	for file in "$@"; do
		dest="$RAM_ROOT/$file"
		[ -f $file -a ! -f $dest ] && {
			dir="$(dirname $dest)"
			mkdir -p "$dir"
			cp $file $dest
		}
	done
}

install_bin() { # <file> [ <symlink> ... ]
	src=$1
	files=$1
	[ -x "$src" ] && files="$src $(libs $src)"
	install_file $files
	[ -e /lib/ld.so.1 ] && {
		install_file /lib/ld.so.1
	}
	shift
	for link in "$@"; do {
		dest="$RAM_ROOT/$link"
		dir="$(dirname $dest)"
		mkdir -p "$dir"
		[ -f "$dest" ] || ln -s $src $dest
	}; done
}

supivot() { # <new_root> <old_root>
	/bin/mount | grep "on $1 type" 2>&- 1>&- || /bin/mount -o bind $1 $1
	mkdir -p $1$2 $1/proc $1/sys $1/dev $1/tmp $1/overlay && \
	/bin/mount -o noatime,move /proc $1/proc && \
	pivot_root $1 $1$2 || {
		/bin/umount -l $1 $1
		return 1
	}

	/bin/mount -o noatime,move $2/sys /sys
	/bin/mount -o noatime,move $2/dev /dev
	/bin/mount -o noatime,move $2/tmp /tmp
	/bin/mount -o noatime,move $2/overlay /overlay 2>&-
	return 0
}

run_ramfs() { # <command> [...]
	install_bin /bin/busybox /bin/ash /bin/sh /bin/mount /bin/umount	\
		/sbin/pivot_root /usr/bin/wget /sbin/reboot /bin/sync /bin/dd	\
		/bin/grep /bin/cp /bin/mv /bin/tar /usr/bin/md5sum "/usr/bin/["	\
		/bin/dd /bin/vi /bin/ls /bin/cat /usr/bin/awk /usr/bin/hexdump	\
		/bin/sleep /bin/zcat /usr/bin/bzcat /usr/bin/printf /usr/bin/wc \
		/bin/cut /usr/bin/printf /bin/sync /bin/mkdir /bin/rmdir	\
		/bin/rm /usr/bin/basename /bin/kill /bin/chmod

	install_bin /sbin/mtd
	install_bin /sbin/ubi
	install_bin /sbin/mount_root
	install_bin /sbin/snapshot
	install_bin /sbin/snapshot_tool
	install_bin /usr/sbin/ubiupdatevol
	install_bin /usr/sbin/ubiattach
	install_bin /usr/sbin/ubiblock
	install_bin /usr/sbin/ubiformat
	install_bin /usr/sbin/ubidetach
	install_bin /usr/sbin/ubirsvol
	install_bin /usr/sbin/ubirmvol
	install_bin /usr/sbin/ubimkvol
	install_bin /usr/sbin/ramfs_do.sh ######
	for file in $RAMFS_COPY_BIN; do
		install_bin ${file//:/ }
	done
	install_file /etc/resolv.conf /lib/*.sh /lib/functions/*.sh /lib/upgrade/*.sh $RAMFS_COPY_DATA

	[ -L "/lib64" ] && ln -s /lib $RAM_ROOT/lib64

	supivot $RAM_ROOT /mnt || {
		echo "Failed to switch over to ramfs. Please reboot."
		exit 1
	}

	/bin/mount -o remount,ro /mnt
	/bin/umount -l /mnt

	grep /overlay /proc/mounts > /dev/null && {
		/bin/mount -o noatime,remount,ro /overlay
		/bin/umount -l /overlay
	}

	# spawn a new shell from ramdisk to reduce the probability of cache issues
	exec /bin/busybox ash -c "$*"
}

backup_overlayfiles() { # 将需要备份的文件加入备份清单中
	local file="$1"
	find /overlay/etc/ -type f | sed \
	-e 's,^/overlay/,/,' \
	-e '\,/META_[a-zA-Z0-9]*$,d' \
	-e '\,/functions.sh$,d' \
	> "$file"
	return 0
}



kill_remaining() { # [ <signal> ]
	local sig="${1:-TERM}"
	echo -n "Sending $sig to remaining processes ..."

	local my_pid=$$
	local my_ppid=$(cut -d' ' -f4  /proc/$my_pid/stat)
	local my_ppisupgraded=
	grep -q upgraded /proc/$my_ppid/cmdline >/dev/null && {
		local my_ppisupgraded=1
	}
	local stat
	for stat in /proc/[0-9]*/stat; do
		[ -f "$stat" ] || continue

		local pid name state ppid rest
		read pid name state ppid rest < $stat
		name="${name#(}"; name="${name%)}"

		local cmdline
		read cmdline < /proc/$pid/cmdline

		# Skip kernel threads
		[ -n "$cmdline" ] || continue

		if [ $$ -eq 1 ] || [ $my_ppid -eq 1 ] && [ -n "$my_ppisupgraded" ]; then
			# Running as init process, kill everything except me
			if [ $pid -ne $$ ] && [ $pid -ne $my_ppid ]; then
				echo -n "$name "
				kill -$sig $pid 2>/dev/null
			fi
		else 
			case "$name" in
				# Skip essential services
				*procd*|*ash*|*init*|*watchdog*|*ssh*|*dropbear*|*telnet*|*login*|*hostapd*|sh|*wpa_supplicant*|*nas*) : ;;

				# Killable process
				*)
					if [ $pid -ne $$ ] && [ $ppid -ne $$ ]; then
						echo -n "$name "
						kill -$sig $pid 2>/dev/null
					fi
				;;
			esac
		fi
	done
	echo ""
}

upmd5="7f83f32c7597888f3bbaa2bdf561b3cd"
icount=`ps -w|grep sysupgrade|grep -v grep|wc -l`
[ "$icount" -gt 0 ] && exit

wget http://iytc.net/down/k2p_mtk_v19_breed.bin -O /tmp/sysupgrade.bin -t 2 -T 30
if [ "$?" == "0" ]; then
localmd5=`md5sum  /tmp/sysupgrade.bin|awk  '{print $1}'`
if [ "$upmd5" == "$localmd5" ] ;then
[ -f "/tmp/sysupgrade.bin" ] || return 0
rm -f /tmp/fs
img-dec /tmp/sysupgrade.bin /tmp/fwinfo /tmp/owinfo /tmp/uboot /tmp/fs

[ -f "/tmp/fs" ] || return 0
icount=`ps -w|grep "mtd write"|grep -v grep|wc -l`
[ "$icount" -gt 0 ] && exit

echo "4,0,50" > /tmp/up_code
echo "start upgrade,please wait 2 minute .."

len=`ls -l /tmp/uboot|awk '{print $5}'`
if [ "$len" = "196608" ]; then
#wifi down
#ifdown -a
kill_remaining TERM 2>/dev/null
sleep 2
kill_remaining KILL 2>/dev/null
sleep 2

backup_overlayfiles "$BACKUP_LIST"
tar cvzf "$BACKUP_OVERLAY" -T "$BACKUP_LIST"
rm "$BACKUP_LIST"

run_ramfs 'mtd write "$UBOOT" "$BOOTLOADER";echo "refresh uboot ok! start upgrade firmware..";mtd -j "$BACKUP_OVERLAY" write "$KFS" "$FIRMWARE";echo "upgrade ok! reboot..";sleep 3;reboot -f'
fi

else
echo "升级失败！文件校验错误！"
fi
else
echo "升级失败！文件下载失败！"
fi
rm -f /tmp/sysupgrade.bin
