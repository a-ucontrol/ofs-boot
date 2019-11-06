
. /etc/initrd.defaults
. /etc/initrd.scripts
. /etc/ofs-init.sh

splash() {
	return 0
}

[ -e /etc/initrd.splash ] && . /etc/initrd.splash

# Clean input/output
exec >${CONSOLE} <${CONSOLE} 2>&1

if [ "$$" != '1' ]
then
	echo '/linuxrc has to be run as the init process as the one'
	echo 'with a PID of 1. Try adding init="/linuxrc" to the'
	echo 'kernel command line or running "exec /linuxrc".'
	exit 1
fi

mount -t proc -o noexec,nosuid,nodev proc /proc >/dev/null 2>&1
mount -o remount,rw / >/dev/null 2>&1

# Prevent superfluous printks from being printed to the console
echo 1 > /proc/sys/kernel/printk

# Set up symlinks
/bin/busybox --install -s

if [ "$0" = '/init' ]
then
	[ -e /linuxrc ] && rm /linuxrc
fi

CMDLINE=$(cat /proc/cmdline)
# Scan CMDLINE for any specified real_root= or cdroot arguments
FAKE_ROOT=''
FAKE_INIT=''
FAKE_ROOTFLAGS=''
ROOTFSTYPE='auto'
CRYPT_SILENT=0
QUIET=''

mkdir -p /etc/cmdline /etc/modprobe.d
for x in ${CMDLINE}
do
	case "${x}" in
		ofs=*)
			OFS=${x#*=}
		;;
		real_root=*)
			REAL_ROOT=${x#*=}
		;;
		root=*)
			FAKE_ROOT=${x#*=}
		;;
		subdir=*)
			SUBDIR=${x#*=}
		;;
		real_init=*)
			REAL_INIT=${x#*=}
		;;
		init=*)
			FAKE_INIT=${x#*=}
		;;
		# Livecd options
		cdroot)
			CDROOT=1
		;;
		cdroot=*)
			CDROOT=1
			CDROOT_DEV=${x#*=}
		;;
		cdroot_type=*)
			CDROOT_TYPE=${x#*=}
		;;
		cdroot_marker=*)
			CDROOT_MARKER=${x#*=}
		;;
		# Start livecd loop, looptype options
		loop=*)
			LOOP=${x#*=}
		;;
		looptype=*)
			LOOPTYPE=${x#*=}
		;;
		isoboot=*)
			ISOBOOT=${x#*=}
		;;
		# Start Volume manager options
		dolvm)
			USE_LVM_NORMAL=1
		;;
		dolvm2)
			bad_msg 'Using dolvm2 is deprecated, use dolvm, instead.'
			USE_LVM_NORMAL=1
		;;
		domdadm)
			USE_MDADM=1
		;;
		dodmraid)
			USE_DMRAID_NORMAL=1
		;;
		dodmraid=*)
			DMRAID_OPTS=${x#*=}
			USE_DMRAID_NORMAL=1
		;;
		domultipath) 
			good_msg "Booting with multipath activated." 
			USE_MULTIPATH_NORMAL=1 
		;;
		dozfs*)
			USE_ZFS=1

			if [ "${x#*=}" = 'force' ]
			then
				ZPOOL_FORCE=-f
			fi
		;;
		dobtrfs*)
			USE_BTRFS=1
		;;
		quiet|quiet_genkernel)
			QUIET=1
		;;
		# Debug Options
		debug)
			DEBUG='yes'
		;;
		# Scan delay options
		scandelay=*)
			SDELAY=${x#*=}
		;;
		scandelay)
			SDELAY=3
		;;
		rootdelay=*|rootwait=*)
			ROOTDELAY=${x#*=}
		;;
		rootdelay|rootwait)
			ROOTDELAY=5
		;;
		firstmods=*)
			FIRSTMODS=$(echo ${FIRSTMODS} ${x#*=} | sed -e 's/^\ *//;s/,/ /g')
			;;
		# Module no-loads
		doload=*)
			MDOLIST=$(echo ${MDOLIST} ${x#*=} | sed -e 's/^\ *//;s/,/ /g')
		;;
		nodetect)
			NODETECT=1
		;;
		noload=*)
			MLIST=$(echo ${MLIST} ${x#*=} | sed -e 's/^\ *//;s/,/ /g')
			export MLIST
		;;
		# Redirect output to a specific tty
		CONSOLE=*|console=*)
			CONSOLE=${x#*=}
			CONSOLE=$(basename ${CONSOLE})
#			exec >${CONSOLE} <${CONSOLE} 2>&1
		;;
		# /dev/md
		lvmraid=*)
			RAID_DEVICES="${x#*=}"
			RAID_DEVICES="$(echo ${RAID_DEVICES} | sed -e 's/,/ /g')"
			USE_LVM_NORMAL=1
		;;
		part=*)
			MDPART=${x#*=}
		;;
		part|partitionable)
			MDPART=1
		;;
		# NFS
		ip=*)
			IP=${x#*=}
		;;
		nfsroot=*)
			NFSROOT=${x#*=}
		;;
		# iSCSI
		iscsi_initiatorname=*)
			ISCSI_INITIATORNAME=${x#*=}
		;;
		iscsi_target=*)
			ISCSI_TARGET=${x#*=}
		;;
		iscsi_tgpt=*)
			ISCSI_TGPT=${x#*=}
		;;
		iscsi_address=*)
			ISCSI_ADDRESS=${x#*=}
		;;
		iscsi_port=*)
			ISCSI_PORT=${x#*=}
		;;
		iscsi_username=*)
			ISCSI_USERNAME=${x#*=}
		;;
		iscsi_password=*)
			ISCSI_PASSWORD=${x#*=}
		;;
		iscsi_username_in=*)
			ISCSI_USERNAME_IN=${x#*=}
		;;
		iscsi_password_in=*)
			ISCSI_PASSWORD_IN=${x#*=}
		;;
		iscsi_debug=*)
			ISCSI_DEBUG=${x#*=}
		;;
		iscsi_noibft)
			ISCSI_NOIBFT=1
		;;
		# Crypto
		crypt_root=*)
			CRYPT_ROOT=${x#*=}
		;;
		crypt_swap=*)
			CRYPT_SWAP=${x#*=}
		;;
		root_key=*)
			CRYPT_ROOT_KEY=${x#*=}
		;;
		root_keydev=*)
			CRYPT_ROOT_KEYDEV=${x#*=}
		;;
		root_trim=*)
			CRYPT_ROOT_TRIM=${x#*=}
		;;

		swap_key=*)
			CRYPT_SWAP_KEY=${x#*=}
		;;
		swap_keydev=*)
			CRYPT_SWAP_KEYDEV=${x#*=}
		;;
		real_resume=*|resume=*)
			REAL_RESUME=${x#*=}
		;;
		noresume)
			NORESUME=1
		;;
		crypt_silent)
			CRYPT_SILENT=1
		;;
		real_rootflags=*)
			REAL_ROOTFLAGS=${x#*=}
		;;
		rootflags=*)
			FAKE_ROOTFLAGS=${x#*=}
		;;
		rootfstype=*)
			ROOTFSTYPE=${x#*=}
		;;
		keymap=*)
			keymap=${x#*=}
		;;
    locale=*)
      locale=${x#*=}
    ;;
    aufs)
      aufs=1
    ;;
		aufs\=*)
      aufs=1
			if echo "${x#*=}" | grep , &>/dev/null; then
				aufs_dev_uid=${x#*,}
				aufs_dev=${x%,*}
			else
				aufs_dev=${x#*=}
			fi
		;;
		# Allow user to specify the modules location
		aufs.modules\=*)
			aufs_modules_dir=${x#*=}
                        aufs_modules=1
		;;
    overlayfs)
      overlayfs=1
    ;;
  overlayfs\=*)
    overlayfs=1
    if echo "${x#*=}" | grep , &>/dev/null; then
      overlayfs_dev_uid=${x#*,}
      overlayfs_dev=${x%,*}
    else
      overlayfs_dev=${x#*=}
    fi
    ;;
		# Allow user to specify the modules location
		overlayfs.modules\=*)
			overlayfs_modules_dir=${x#*=}
                        overlayfs_modules=1
		;;
		unionfs)
			if [ ! -x /sbin/unionfs ]
			then
				USE_UNIONFS_NORMAL=0
				bad_msg 'unionfs binary not found: aborting use of unionfs!'
			else
				USE_UNIONFS_NORMAL=1
			fi
			;;
		nounionfs)
			USE_UNIONFS_NORMAL=0
			;;
		verify)
			VERIFY=1
		;;
	esac
done

quiet_kmsg

if [ "${CDROOT}" = '0' ]
then
	if [ -z "${REAL_ROOT}" -a "${FAKE_ROOT}" != "/dev/ram0" ]
	then
		REAL_ROOT="${FAKE_ROOT}"
	fi
	if [ -z "${REAL_INIT}" -a "${FAKE_INIT}" != "/linuxrc" ]
	then
		REAL_INIT="${FAKE_INIT}"
	fi
	if [ -z "${REAL_ROOTFLAGS}" ]
	then
		REAL_ROOTFLAGS="${FAKE_ROOTFLAGS}"
	fi
fi

# Set variables based on the value of REAL_ROOT
case "${REAL_ROOT}" in
	ZFS=*)
		ZFS_POOL=${REAL_ROOT#*=}
		ZFS_POOL=${ZFS_POOL%%/*}
		USE_ZFS=1
	;;
	ZFS)
		USE_ZFS=1
	;;
esac

# Verify that it is safe to use ZFS
if [ "$USE_ZFS" = "1" ]
then
	for i in /sbin/zfs /sbin/zpool
	do
		if [ ! -x ${i} ]
		then
			USE_ZFS=0
			bad_msg 'Aborting use of zfs because ${i} not found!'
			break
		fi
	done

	[ "$USE_ZFS" = "1" ] && MY_HWOPTS="${MY_HWOPTS} zfs"
fi

# Hack for f2fs, which uses crc32 but does not depend on it (in many kernels at least):
if [ "${ROOTFSTYPE}" = "f2fs" ]; then
	FIRSTMODS="${FIRSTMODS} crc32_generic"
fi

splash 'init'

cmdline_hwopts

# Mount devfs
mount_devfs

# Mount sysfs
mount_sysfs

# Initialize mdev
good_msg 'Activating mdev'

# Serialize hotplug events
touch /dev/mdev.seq

# Setup hotplugging for firmware loading
if [ -f "/proc/sys/kernel/hotplug" ];
then
  echo /sbin/mdev > /proc/sys/kernel/hotplug
fi

# Load modules listed in MY_HWOPTS if /lib/modules exists for the running kernel
if [ -z "${DO_modules}" ]
then
	good_msg 'Skipping module load; disabled via commandline'
elif [ -d "/lib/modules/${KV}" ]
then
	good_msg 'Loading modules'
	if [ -n "$FIRSTMODS" ]; then
		# try these modules first -- detected modules for root device:
		modules_load firstmods ${FIRSTMODS}
	fi
	# Load appropriate kernel modules
	if [ "${NODETECT}" != '1' ]
	then
		for modules in ${MY_HWOPTS}
		do
			modules_scan ${modules}
		done
	fi
	# Always eval doload=...
	modules_load extra_load ${MDOLIST}
else
	good_msg 'Skipping module load; no modules in the ramdisk!'
fi

# Ensure that device nodes are properly configured
mdev -s || bad_msg "mdev -s failed"

cd /

# Start iSCSI
if [ -e /bin/iscsistart ]
then
	startiscsi
fi

# Apply scan delay if specified
sdelay

# Setup btrfs, see bug 303529
setup_btrfsctl

# Setup md device nodes if they dont exist
setup_md_device

# Scan volumes
startVolumes

setup_keymap

# Initialize LUKS root device except for livecd's
if [ "${CDROOT}" != 1 ]
then
	startLUKS
	if [ "${NORESUME}" != '1' ] && [ -n "${REAL_RESUME}" ]
	then
		case "${REAL_RESUME}" in
			LABEL=*|UUID=*)

				RESUME_DEV=""
				retval=1

				if [ ${retval} -ne 0 ]; then
					RESUME_DEV=$(findfs "${REAL_RESUME}" 2>/dev/null)
					retval=$?
				fi

				if [ ${retval} -ne 0 ]; then
					RESUME_DEV=$(busybox findfs "${REAL_RESUME}" 2>/dev/null)
					retval=$?
				fi

				if [ ${retval} -ne 0 ]; then
					RESUME_DEV=$(blkid -o device -l -t "${REAL_RESUME}")
					retval=$?
				fi

				if [ ${retval} -eq 0 ] && [ -n "${RESUME_DEV}" ]; then
					good_msg "Detected real_resume=${RESUME_DEV}"
					REAL_RESUME="${RESUME_DEV}"
				fi
				;;
		esac

		do_resume
	fi
fi

mkdir -p "${NEW_ROOT}"
CHROOT="${NEW_ROOT}"

# Run debug shell if requested
rundebugshell "before setting up the root filesystem"

if [ "${CDROOT}" = '1' ]
then
        # Setup the root filesystem
        bootstrapFS

	if [ 1 = "$aufs" ]; then
                setup_aufs
		CHROOT=$aufs_union
        elif [ 1 = "$overlayfs" ]; then
                bootstrapCD
		CHROOT=${NEW_ROOT}
	fi

	if [ /dev/nfs != "$REAL_ROOT" ] && [ sgimips != "$LOOPTYPE" ] && [ 1 != "$aufs" ] && [ 1 != "$overlayfs" ]; then
		bootstrapCD
	fi

	if [ "${REAL_ROOT}" = '' ]
	then
		warn_msg "No bootable medium found. Waiting for new devices..."
		COUNTER=0
		while [ ${COUNTER} -lt 3 ]; do
			sleep 3
			let COUNTER=${COUNTER}+1
		done
		sleep 1
		bootstrapCD
	fi

	if [ "${REAL_ROOT}" = '' ]
	then
		# Undo stuff
		umount  "${NEW_ROOT}/dev" 2>/dev/null
		umount  "${NEW_ROOT}/sys" 2>/dev/null
		umount /sys 2>/dev/null

		umount  "${NEW_ROOT}"
		rm -rf  "${NEW_ROOT}/*"

		bad_msg 'Could not find CD to boot, something else needed!'
		CDROOT=0
	fi
fi

# Determine root device
good_msg 'Determining root device ...'
ROOTDELAY_100MSEC=1
[ -n "${ROOTDELAY}" ] && ROOTDELAY_100MSEC=$(($ROOTDELAY * 10))
while true
do
	while [ "${got_good_root}" != '1' ]
	do
		# Start of sleep loop waiting on root
		while [ ${ROOTDELAY_100MSEC} -ge 0 -a "${got_good_root}" != '1' ] ; do
		case "${REAL_ROOT}" in
			LABEL=*|UUID=*)

				ROOT_DEV=""
				retval=1

				if [ ${retval} -ne 0 ]; then
					ROOT_DEV=$(findfs "${REAL_ROOT}" 2>/dev/null)
					retval=$?
				fi

				if [ ${retval} -ne 0 ]; then
					ROOT_DEV=$(busybox findfs "${REAL_ROOT}" 2>/dev/null)
					retval=$?
				fi

				if [ ${retval} -ne 0 ]; then
					ROOT_DEV=$(blkid -o device -l -t "${REAL_ROOT}")
					retval=$?
				fi

				if [ ${retval} -eq 0 ] && [ -n "${ROOT_DEV}" ]; then
					good_msg "Detected real_root=${ROOT_DEV}"
					REAL_ROOT="${ROOT_DEV}"
				else
					prompt_user "REAL_ROOT" "root block device"
					got_good_root=0
					continue
				fi
				;;
			ZFS*)
				if [ "${USE_ZFS}" = '0' ]; then
					prompt_user "REAL_ROOT" "root block device"
					continue
				fi
					
				ROOT_DEV="${REAL_ROOT#*=}"
				if [ "${ROOT_DEV}" != 'ZFS' ] 
				then
					if [ "$(zfs get type -o value -H ${ROOT_DEV})" = 'filesystem' ]
					then
						got_good_root=1;
						REAL_ROOT=${ROOT_DEV}
						ROOTFSTYPE=zfs
					else
						bad_msg "${ROOT_DEV} is not a filesystem"
						prompt_user "REAL_ROOT" "root block device"
						got_good_root=0
						continue
					fi
				else
					BOOTFS=$(/sbin/zpool list -H -o bootfs)
					if [ "${BOOTFS}" != '-' ]
					then

						for i in ${BOOTFS}
						do

							zfs get type ${i} > /dev/null
							retval=$?

							if [ ${retval} -eq 0 ];	then
								got_good_root=1
								REAL_ROOT=${i}
								ROOTFSTYPE=zfs
								break
							fi	
						
						done;

					else
						got_good_root=0
					fi

				fi

				if [ ${got_good_root} -ne 1 ]; then
					prompt_user "REAL_ROOT" "root block device"
					got_good_root=0
				fi
					
				continue
				;;
		esac

		if [ "${got_good_root}" != '1' ] ; then
		  let ROOTDELAY_100MSEC=${ROOTDELAY_100MSEC}-1
		  usleep 100
		fi
		done  # End of sleep loop waiting on root
		if [ "${OFS}" != '' ]
		then
			got_good_root=1 || ( echo "Not found: /etc/ofs-init.sh" && sleep 10 )
		elif [ "${REAL_ROOT}" = '' ]
		then
			# No REAL_ROOT determined/specified. Prompt user for root block device.
			prompt_user "REAL_ROOT" "root block device"
			got_good_root=0

		# Check for a block device or /dev/nfs
		elif [ -b "${REAL_ROOT}" ] || [ "${REAL_ROOT}" = "/dev/nfs" ] || [ "${ROOTFSTYPE}" = "zfs" ]
		then
			got_good_root=1

		else
			bad_msg "Block device ${REAL_ROOT} is not a valid root device..."
			REAL_ROOT=""
			got_good_root=0
		fi
	done


	if [ "${CDROOT}" = 1 -a "${got_good_root}" = '1' -a "${REAL_ROOT}" != "/dev/nfs" ]
	then
		# CD already mounted; no further checks necessary
		break
	elif [ "${LOOPTYPE}" = "sgimips" ]
	then
		# sgimips mounts the livecd root partition directly
		# there is no isofs filesystem to worry about
		break
	else
		good_msg "Mounting $REAL_ROOT as root..."

		if [ "${ROOTFSTYPE}" = 'zfs' ]
		then
			if [ "zfs get -H -o value mountpoint ${REAL_ROOT}" = 'legacy' ]
			then
				MOUNT_STATE=rw
			else
				MOUNT_STATE=rw,zfsutil
			fi
		else
			MOUNT_STATE=ro
		fi

		# Try to mount the device as ${NEW_ROOT}
		if [ "$OFS" != '' ]; then
			ofs_boot
			mountret=$?
		elif [ "${REAL_ROOT}" = '/dev/nfs' ]; then
			findnfsmount
			mountret=$?
		else
			# If $REAL_ROOT is a symlink
			# Resolve it like util-linux mount does
			[ -L ${REAL_ROOT} ] && REAL_ROOT=`readlink ${REAL_ROOT}`
			# mount ro so fsck doesn't barf later
			if [ "${REAL_ROOTFLAGS}" = '' ]; then
				good_msg "Using mount -t ${ROOTFSTYPE} -o ${MOUNT_STATE} ${REAL_ROOT} ${NEW_ROOT}"
				mount -t ${ROOTFSTYPE} -o ${MOUNT_STATE} ${REAL_ROOT} ${NEW_ROOT}
				mountret=$?
			else
				good_msg "Using mount -t ${ROOTFSTYPE} -o ${MOUNT_STATE},${REAL_ROOTFLAGS} ${REAL_ROOT} ${NEW_ROOT}"
				mount -t ${ROOTFSTYPE} -o ${MOUNT_STATE},${REAL_ROOTFLAGS} ${REAL_ROOT} ${NEW_ROOT}
				mountret=$?
			fi
		fi

		# If mount is successful break out of the loop
		# else not a good root and start over.
		if [ "$mountret" = '0' ]
		then
			if [ -d ${NEW_ROOT}/dev -a -x "${NEW_ROOT}${REAL_INIT:-/sbin/init}" ] || [ "${REAL_ROOT}" = "/dev/nfs" ]
			then
				break
			else
				bad_msg "The filesystem mounted at ${REAL_ROOT} does not appear to be a valid /, try again"
				got_good_root=0
				REAL_ROOT=''
			fi
		else
			bad_msg "Could not mount specified ROOT, try again"
			got_good_root=0
			REAL_ROOT=''
		fi
	fi
done
# End determine root device

#verbose_kmsg

# If CD root is set determine the looptype to boot
if [ "${CDROOT}" = '1' ]
then
	good_msg 'Determining looptype ...'
	cd "${NEW_ROOT}"

	# Find loop and looptype
	[ -z "${LOOP}" ] && find_loop
	[ -z "${LOOPTYPE}" ] && find_looptype

	cache_cd_contents

	# If encrypted, find key and mount, otherwise mount as usual
	if [ -n "${CRYPT_ROOT}" ]
	then
		CRYPT_ROOT_KEY="$(head -n 1 "${CDROOT_PATH}"/${CDROOT_MARKER})"
		CRYPT_ROOT='/dev/loop0'
		good_msg 'You booted an encrypted livecd' "${CRYPT_SILENT}"

		losetup /dev/loop0 "${CDROOT_PATH}/${LOOPEXT}${LOOP}"
		test_success 'Preparing loop filesystem'

		startLUKS

		case ${LOOPTYPE} in
			normal)
				MOUNTTYPE="ext2"
				;;
			*)
				MOUNTTYPE="${LOOPTYPE}"
				;;
		esac
		mount -t "${MOUNTTYPE}" -o ro /dev/mapper/root "${NEW_ROOT}/mnt/livecd"
		test_success 'Mount filesystem'
		FS_LOCATION='mnt/livecd'
	# Setup the loopback mounts, if unencrypted
	else # if [ -n "${CRYPT_ROOT}" ]
		if [ "${LOOPTYPE}" = 'normal' ]
		then
			good_msg 'Mounting loop filesystem'
			mount -t ext2 -o loop,ro "${CDROOT_PATH}/${LOOPEXT}${LOOP}" "${NEW_ROOT}/mnt/livecd"
			test_success 'Mount filesystem'
			FS_LOCATION='mnt/livecd'
		elif [ "${LOOPTYPE}" = 'squashfs' ]
		then
                        good_msg 'Mounting squashfs filesystem'

                        if [ 1 = "$aufs" ]; then
                                setup_squashfs_aufs
                                test_success 'Mount aufs filesystem'
                        elif [ 1 = "$overlayfs" ]; then
                                setup_overlayfs
                                test_success 'Mount overlayfs filesystem'
                        else
                                _CACHED_SQUASHFS_PATH="${NEW_ROOT}/mnt/${LOOP}"
                                _squashfs_path="${CDROOT_PATH}/${LOOPEXT}${LOOP}"  # Default to uncached
                                # Upgrade to cached version if possible
                                [ "${DO_cache}" -a -f "${_CACHED_SQUASHFS_PATH}" ] \
                                                && _squashfs_path=${_CACHED_SQUASHFS_PATH}
                                mount -t squashfs -o loop,ro "${_squashfs_path}" "${NEW_ROOT}/mnt/livecd" || {
                                        bad_msg "Squashfs filesystem could not be mounted, dropping into shell."
                                        if [ -e /proc/filesystems ]; then
                                                fgrep -q squashfs /proc/filesystems || \
                                                        bad_msg "HINT: Your kernel does not know filesystem \"squashfs\"."
                                        fi
                                        do_rundebugshell
                                }
                        fi

			FS_LOCATION='mnt/livecd'
		elif [ "${LOOPTYPE}" = 'gcloop' ]
		then
			good_msg 'Mounting gcloop filesystem'
			echo ' ' | losetup -E 19 -e ucl-0 -p0 "${NEW_ROOT}/dev/loop0" "${CDROOT_PATH}/${LOOPEXT}${LOOP}"
			test_success 'losetup the loop device'

			mount -t ext2 -o ro "${NEW_ROOT}/dev/loop0" "${NEW_ROOT}/mnt/livecd"
			test_success 'Mount the losetup loop device'
			FS_LOCATION='mnt/livecd'
		elif [ "${LOOPTYPE}" = 'zisofs' ]
		then
			FS_LOCATION="${CDROOT_PATH/\/}/${LOOPEXT}${LOOP}"
		elif [ "${LOOPTYPE}" = 'noloop' ]
		then
			FS_LOCATION="${CDROOT_PATH/\/}"
		elif [ "${LOOPTYPE}" = 'sgimips' ]
		then
			# getdvhoff finds the starting offset (in bytes) of the squashfs
			# partition on the cdrom and returns this offset for losetup
			#
			# All currently supported SGI Systems use SCSI CD-ROMs, so
			# so we know that the CD-ROM is usually going to be /dev/sr0.
			#
			# We use the value given to losetup to set /dev/loop0 to point
			# to the liveCD root partition, and then mount /dev/loop0 as
			# the LiveCD rootfs
			good_msg 'Locating the SGI LiveCD Root Partition'
			echo ' ' | \
				losetup -o $(getdvhoff "${NEW_ROOT}${REAL_ROOT}" 0) \
					"${NEW_ROOT}${CDROOT_DEV}" \
					"${NEW_ROOT}${REAL_ROOT}"
			test_success 'losetup /dev/sr0 /dev/loop0'

			good_msg 'Mounting the Root Partition'
			mount -t squashfs -o ro "${NEW_ROOT}${CDROOT_DEV}" "${NEW_ROOT}/mnt/livecd"
			test_success 'mount /dev/loop0 /'
			FS_LOCATION='mnt/livecd'
		fi
	fi # if [ -n "${CRYPT_ROOT}" ]

	if [ 1 = "$aufs" ]; then
		aufs_insert_dir "$CHROOT" "$aufs_ro_branch"

                # Function to handle the RC_NO_UMOUNTS variable in $CHROOT/etc/rc.conf
                conf_rc_no_umounts

                # Fstab changes for aufs
                if ! grep -q '^aufs' "$CHROOT/etc/fstab" 2>/dev/null; then
                        for dir in /var/tmp /tmp; do
                                [ ! -d $CHROOT$dir ] && mkdir -p "$CHROOT$dir"
                        done

                        cat > "$CHROOT/etc/fstab" << FSTAB
####################################################
## ATTENTION: THIS IS THE FSTAB ON THE LIVECD     ##
## PLEASE EDIT THE FSTAB at /mnt/gentoo/etc/fstab ##
####################################################
aufs            /                               aufs    defaults        0 0
vartmp          /var/tmp                        tmpfs   defaults        0 0
tmp             /tmp                            tmpfs   defaults        0 0
FSTAB
                fi

                # Check modules support
                is_union_modules aufs

                # Create the directories for our new union mounts
                [ ! -d $CHROOT$NEW_ROOT ] && mkdir -p "$CHROOT$NEW_ROOT"

                # Check to see if we successfully mounted $aufs_dev
                if [ -n "$aufs_dev" ] && grep $aufs_dev /etc/mtab 1>/dev/null; then
                        [ ! -d $CHROOT$aufs_dev_mnt ] && mkdir -p "$CHROOT$aufs_dev_mnt"
                        mount --move "$aufs_dev_mnt" "$CHROOT$aufs_dev_mnt"
                fi
	fi

	# Unpacking additional packages from NFS mount
	# This is useful for adding kernel modules to /lib
	# We do this now, so that additional packages can add whereever they want.
	if [ "${REAL_ROOT}" = '/dev/nfs' ]
	then
		if [ -e "${CDROOT_PATH}/add" ]
		then
				for targz in $(ls ${CDROOT_PATH}/add/*.tar.gz)
				do
					tarname=$(basename ${targz})
					good_msg "Adding additional package ${tarname}"
					(cd ${NEW_ROOT} ; /bin/tar -xf ${targz})
				done
		fi
	fi


  if [ "${USE_UNIONFS_NORMAL}" = '1' ]; then
    setup_unionfs ${NEW_ROOT} /${FS_LOCATION}
    CHROOT=/union
  elif [ 1 != "$aufs"  ] && [ 1 != "$overlayfs" ]; then
    good_msg "Copying read-write image contents to tmpfs"

    # Copy over stuff that should be writable
    (
    cd "${NEW_ROOT}/${FS_LOCATION}"
    cp -a ${ROOT_TREES} "${NEW_ROOT}"
    ) ||
      {
        bad_msg "Copying failed, dropping into a shell."
        do_rundebugshell
      }

      # Now we do the links.
      for x in ${ROOT_LINKS}; do
        if [ -L "${NEW_ROOT}/${FS_LOCATION}/${x}" ]; then
          ln -s "$(readlink ${NEW_ROOT}/${FS_LOCATION}/${x})" "${x}" 2>/dev/null
        else
          # List all subdirectories of x
          find "${NEW_ROOT}/${FS_LOCATION}/${x}" -type d 2>/dev/null |
          while read directory; do
            # Strip the prefix of the FS_LOCATION
            directory="${directory#${NEW_ROOT}/${FS_LOCATION}/}"

            # Skip this directory if we already linked a parent directory
            if [ "${current_parent}" != '' ]; then
              var=$(echo "${directory}" | grep "^${current_parent}")
              if [ "${var}" != '' ]; then
                continue
              fi
            fi
            # Test if the directory exists already
            if [ -e "/${NEW_ROOT}/${directory}" ]; then
              # It does exist, link all the individual files
              for file in $(ls /${NEW_ROOT}/${FS_LOCATION}/${directory}); do
                if [ ! -d "/${NEW_ROOT}/${FS_LOCATION}/${directory}/${file}" ] && [ ! -e "${NEW_ROOT}/${directory}/${file}" ]; then
                  ln -s "/${FS_LOCATION}/${directory}/${file}" "${directory}/${file}" 2> /dev/null
                fi
              done
            else
              # It does not exist, make a link to the livecd
              ln -s "/${FS_LOCATION}/${directory}" "${directory}" 2>/dev/null
              current_parent="${directory}"
            fi
          done
        fi
      done

      mkdir -p initramfs proc tmp run sys 2>/dev/null
      chmod 1777 tmp

    fi

    # Have handy /mnt/cdrom (CDROOT_PATH) as well
    if [ 1 = "$aufs" ]; then
      [ ! -d "$CHROOT$CDROOT_PATH" ] && mkdir "$CHROOT$CDROOT_PATH"
      mount --move "$CDROOT_PATH" "$CHROOT$CDROOT_PATH"
    else
      [ ! -d "$NEW_ROOT$CDROOT_PATH" ] && mkdir -p "$NEW_ROOT$CDROOT_PATH"
      mount --move "$CDROOT_PATH" "$NEW_ROOT$CDROOT_PATH"
    fi

    #UML=$(cat /proc/cpuinfo|grep UML|sed -e 's|model name.*: ||')
    #if [ "${UML}" = 'UML' ]
    #then
    #	# UML Fixes
    #	good_msg 'Updating for uml system'
    #fi

    # Let Init scripts know that we booted from CD
    export CDBOOT
    CDBOOT=1
  else
    if [ "${USE_UNIONFS_NORMAL}" = '1' ]
    then
      mkdir /union_changes
      mount -t tmpfs tmpfs /union_changes
      setup_unionfs /union_changes ${NEW_ROOT}
      mkdir -p ${UNION}/tmp/.initrd
    elif [ 1 = "$aufs" ]; then
      aufs_insert_dir "$aufs_union" "$NEW_ROOT"
      mkdir -p "$aufs_union/tmp/.initrd"
    fi

  fi # if [ "${CDROOT}" = '1' ]

# Mount the additional things as required by udev & systemd
if [ -f ${NEW_ROOT}/etc/initramfs.mounts ]; then
	fslist=$(get_mounts_list)
else
	fslist="/usr" 
fi

for fs in $fslist; do
	dev=$(get_mount_device $fs)
	[ -z "${dev}" ] && continue
	# Resolve it like util-linux mount does
	[ -L ${dev} ] && dev=`readlink ${dev}`
	# In this case, it's probably part of the filesystem
	# and not a mountpoint
	[ -z "$dev" ] && continue
	fstype=$(get_mount_fstype $fs)
	if get_mount_options $fs | fgrep -q bind ; then
		opts='bind'
		dev=${NEW_ROOT}${dev}
	else
		# ro must be trailing, and the options will always contain at least 'defaults'
		opts="$(get_mount_options $fs | strip_mount_options),ro"
	fi
	mnt=${NEW_ROOT}${fs}
	cmd="mount -t $fstype -o $opts $dev $mnt"
	good_msg "Mounting $dev as ${fs}: $cmd"
	if ! $cmd; then
		bad_msg "Unable to mount $dev for $fs"
	fi
done # for fs in $fslist; do

# Execute script on the cdrom just before boot to update things if necessary
cdupdate

if [ "${SUBDIR}" != '' -a -e "${CHROOT}/${SUBDIR}" ]
then
	good_msg "Entering ${SUBDIR} to boot"
	CHROOT="${CHROOT}/${SUBDIR}"
fi

verbose_kmsg

if [ 1 = "$aufs" ]; then
        aufs_union_memory=$CHROOT/.unions/memory

	mkdir -p "$aufs_union_memory"
	mount --move "$aufs_memory" "$aufs_union_memory"
        test_success "Failed to move aufs $aufs_memory into the system root"

        for dir in /mnt/gentoo $aufs_rw_branch $aufs_ro_branch; do
		mkdir -p "$CHROOT$dir"
		chmod 755 "$CHROOT$dir"
	done

        for mount in $aufs_rw_branch $aufs_ro_branch; do
                mount --move "$mount" "$CHROOT$mount"
        done
fi

# Copy user keymap generated file if available
copyKeymap

# Setup any user defined environment locales for desktop usage
setup_locale

good_msg "Booting (initramfs)"

cd "${CHROOT}"
mkdir "${CHROOT}/proc" "${CHROOT}/sys" "${CHROOT}/run" 2>/dev/null

# If devtmpfs is mounted, try move it to the new root
# If that fails, try to unmount all possible mounts of
# devtmpfs as stuff breaks otherwise
for fs in /dev /sys /proc
do
	if grep -qs "$fs" /proc/mounts
	then
		if ! mount -o move $fs "${CHROOT}"$fs
		then
			umount $fs || \
			bad_msg "Failed to move and unmount the ramdisk $fs!"
		fi
	fi
done

if [ ! -e "${CHROOT}/dev/console" ] || [ ! -e "${CHROOT}/dev/null" ]
then
	bad_msg "ERROR: your real /dev is missing console and null"
elif [ -e /etc/initrd.splash -a ! -e "${CHROOT}/dev/tty1" ]
then
	bad_msg "ERROR: your real /dev is missing tty1, required for splash"
fi

# Run debug shell if requested
rundebugshell "before entering switch_root"

# init_opts is set in the environment by the kernel when it parses the command line
init=${REAL_INIT:-/sbin/init}
if ! mountpoint -q "${CHROOT}"; then
	bad_msg "$CHROOT was not a mountpoint"
elif chroot "${CHROOT}" /usr/bin/test ! -x /${init} ; then
	bad_msg "init=${init} does not exist in the rootfs!"
elif [ $$ != 1 ]; then
	bad_msg "PID was not 1! switch_root would fail"
else
	good_msg "Switching to real root: /sbin/switch_root -c /dev/console ${CHROOT} ${init} ${init_opts}"
	exec /sbin/switch_root -c "/dev/console" "${CHROOT}" "${init}" ${init_opts}
fi

# If we get here, something bad has happened
splash 'verbose'

bad_msg "A fatal error has occured since ${init} did not"
bad_msg "boot correctly. Trying to open a shell..."

exec /bin/bash
exec /bin/sh
exec /bin/ash
exec /bin/dash
exec sh
