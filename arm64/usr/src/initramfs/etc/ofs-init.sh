quiet_kmsg(){
return 0
}

verbose_kmsg(){
return 0
}

ofs_boot(){
for i in $(echo $OFS | sed -e 's/,/ /g') ; do [ "$(echo $i | grep "^ro" | grep ".squashfs$")" != "" ] && LRO=$i && continue || [ "$(echo $i | grep ^system | grep  .squashfs$)" != "" ] && LSYSTEM=$i && continue || [ "$(echo $i | grep ^rw | grep  .loop$)" != "" ] && LRW=$i && continue || [ "$(echo $i | grep ^rw | grep  .part$)" != "" ] && PRW=$i && continue ; done
MP=/run/ofs/mount && mkdir -p $MP
DEVICES=$(blkid -o device | grep "[1-9].*$" | sed s/"\/dev\/"//)
fs_t(){ VFAT=$(mount | grep /dev/$d | grep "type vfat") || EXFAT=$(mount | grep /dev/$d | grep "type exfat") || NTFS=$(mount | grep /dev/$d | grep "type ntfs-3g") ; }
find_dev(){ DEV="" ; for d in $DEVICES ; do mount -t ext4,vfat,exfat,ntfs-3g /dev/$d $MP -o ro >/dev/null 2>&1 ; RET=$? ; [ "$RET" == "0" ] && [ -f $1 ] && DEV=$d && fs_t ; [ "$RET" == "0" ] && umount $MP ; [ "$DEV" != "" ] && break ; done }
OFS_BASE=$MP/gentoo ; find_dev $OFS_BASE/system/$LSYSTEM
if [ "$DEV" != '' ] ; then
	MO() { ( [ "$VFAT" != "" ] &&  echo "-t vfat -o rw,fmask=0111,dmask=0000" )  || ( [ "$EXFAT" != "" ] &&  echo "-t exfat -o rw,fmask=0111,dmask=0000" ) || ( [ "$NTFS" != "" ] &&  echo "-t ntfs-3g -o rw,fmask=0111,dmask=0000,force" ) || echo "-t ext4" ; }
	OFS_BOOT=$DEV ; [ ! -n "$QUIET" ] && mount $(MO) /dev/$OFS_BOOT $MP || mount $(MO) /dev/$OFS_BOOT $MP > /dev/null 2>&1
	mount -t squashfs $OFS_BASE/system/$LSYSTEM $OFS_BASE/system -o ro || got_good_root=0
	[ -f $OFS_BASE/ro/$LRO ] && mount -t squashfs $OFS_BASE/ro/$LRO $OFS_BASE/ro -o ro
	MP=$OFS_BASE/rw ; [ "$PRW" != "" ] && find_dev $OFS_BASE/rw/$PRW && OFS_RW_DEV=$DEV && mount -t ext4 /dev/$OFS_RW_DEV $MP
	[ "$?" != "0" ] && [ -f $OFS_BASE/rw/$LRW  ] &&  mount -t ext4 $OFS_BASE/rw/$LRW $MP -o rw
	[ ! -d $OFS_BASE/rw/ud ] && mkdir $OFS_BASE/rw/ud
	[ ! -d $OFS_BASE/rw/wd ] && mkdir $OFS_BASE/rw/wd
	mount -t overlay overlay ${NEW_ROOT} -o ro,noatime,nodiratime,lowerdir=$OFS_BASE/ro:$OFS_BASE/system,upperdir=$OFS_BASE/rw/ud,workdir=$OFS_BASE/rw/wd || got_good_root=0
	if [ "$got_good_root" == "1" ] ; then
		mount -t tmpfs tmpfs -o mode=0755,nodev,size=10% ${NEW_ROOT}/run ; mkdir -p ${NEW_ROOT}/run/ofs ; chmod 0700 ${NEW_ROOT}/run/ofs
		echo 'SUBSYSTEM=="block", KERNEL=="'$OFS_BOOT'", ENV{UAM_IGNORE}="1", SYMLINK+="ofs-boot"' > ${NEW_ROOT}/run/ofs/devs && OFS_BOOT=$(echo $OFS_BOOT | sed s/[0-9]*$/*/) && echo 'SUBSYSTEM=="block", KERNEL=="'$OFS_BOOT'", ENV{UDISKS_IGNORE}="1"' >> ${NEW_ROOT}/run/ofs/devs
		[ "$OFS_RW_DEV" != "" ] && echo 'SUBSYSTEM=="block", KERNEL=="'$OFS_RW_DEV'", ENV{UAM_IGNORE}="1", SYMLINK+="ofs-rw-part"' >> ${NEW_ROOT}/run/ofs/devs && OFS_RW_DEV=$(echo $OFS_RW_DEV | sed s/[0-9]*$/*/) && [ "$OFS_RW_DEV" != "$OFS_BOOT" ] && echo 'SUBSYSTEM=="block", KERNEL=="'$OFS_RW_DEV'", ENV{UDISKS_IGNORE}="1"' >> ${NEW_ROOT}/run/ofs/devs
		echo OFS=$OFS > ${NEW_ROOT}/run/ofs/initramfs-info ; echo -e "\nLRO=$LRO\nLSYSTEM=$LSYSTEM\nLRW=$LRW\nPRW=$PRW\n" >> ${NEW_ROOT}/run/ofs/initramfs-info ; mount >> ${NEW_ROOT}/run/ofs/initramfs-info
		mkdir -p ${NEW_ROOT}/run/ofs/mount && mount --move /run/ofs/mount ${NEW_ROOT}/run/ofs/mount
		[ ! -n "$QUIET" ] && cat ${NEW_ROOT}/run/ofs/initramfs-info
	fi
else
	got_good_root=0
fi
if [ "$got_good_root" != "1" ] ; then
	bad_msg "OFS boot failed, dropping into a shell."
	do_rundebugshell
fi
}
