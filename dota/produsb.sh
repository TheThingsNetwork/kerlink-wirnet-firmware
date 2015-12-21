#!/bin/sh
#
#  Produsb.sh
#
# This script is sourced by initramfs in ${MOUNT_POINT} directory (mount point of /dev/sda1)
#
# ROOTFS_IMAGE=rootfs.tar.gz
# USERFS_IMAGE=userfs.tar.gz
# KERNEL_IMAGE=uImage
# INITRAMFS_IMAGE=initramfs.cpio.gz.uboot
# SCRIPT_IMAGE=script_uboot.img
# UBOOT_IMAGE=u-boot.bin
# FS_RESCUE=fs_rescue.tar.gz
# FS_RESCUE_UPDATE=fs_rescue_update.tar.gz
# C8051_IMAGE=c8051.bin

UPDATE_FILE="produsb.tar.gz"

DOTA_PATH=${MOUNT_POINT_USERFS}/${DOTA_DIR}

KNET_ID=$(get_uvar ethaddr | awk -F\: '{print $3$4$5$6}')

# U-Boot
if [ -f ${MOUNT_POINT}/${UBOOT_IMAGE} ]
then
	cp ${MOUNT_POINT}/${UBOOT_IMAGE} ${TMP_DIR}/${UBOOT_IMAGE}
	update_uboot ${TMP_DIR}/${UBOOT_IMAGE}
	[ $? -eq 0 ] && echo "U-Boot updated"
	# Reflash Env to be sure
	(
	nanddump -o -b -n -f ${TMP_DIR}/uenv /dev/mtd2
	flash_eraseall /dev/mtd2
	nandwrite /dev/mtd2 ${TMP_DIR}/uenv
	) > /dev/null 2>&1
	info "U-Boot Env updated"
	echo ""

fi

# Script
if [ -f ${MOUNT_POINT}/${SCRIPT_IMAGE} ]
then
	cp ${MOUNT_POINT}/${SCRIPT_IMAGE} ${TMP_DIR}/${SCRIPT_IMAGE}
	prod_flash_script ${TMP_DIR}/${SCRIPT_IMAGE}
	[ $? -eq 0 ] && echo "Script Updated"
fi

# Kernel
if [ -f ${MOUNT_POINT}/${KERNEL_IMAGE} ]
then
	cp ${MOUNT_POINT}/${KERNEL_IMAGE} ${TMP_DIR}/${KERNEL_IMAGE}
	prod_flash_kernel ${TMP_DIR}/${KERNEL_IMAGE}
	[ $? -eq 0 ] && echo "Kernel updated"
fi

# Initramfs
if [ -f ${MOUNT_POINT}/${INITRAMFS_IMAGE} ]
then
	cp ${MOUNT_POINT}/${INITRAMFS_IMAGE} ${TMP_DIR}/${INITRAMFS_IMAGE}
	prod_flash_initramfs ${TMP_DIR}/${INITRAMFS_IMAGE}
	[ $? -eq 0 ] && echo "Initramfs updated"
fi

# Rootfs & rescuefs
if [ -f ${MOUNT_POINT}/${ROOTFS_IMAGE} ]
then
	cp ${MOUNT_POINT}/${ROOTFS_IMAGE} ${TMP_DIR}/${ROOTFS_IMAGE}
	prod_flash_rootfs ${TMP_DIR}/${ROOTFS_IMAGE}
	[ $? -eq 0 ] && echo "Rootfs updated"
fi

# Userfs
if [ -f ${MOUNT_POINT}/${USERFS_IMAGE} ]
then
	wirma2hw wd timeout 300
	cp ${MOUNT_POINT}/${USERFS_IMAGE} ${TMP_DIR}/${USERFS_IMAGE}
	update_userfs ${TMP_DIR}/${USERFS_IMAGE}

	[ $? -eq 0 ] && echo "Userfs updated"
fi

# Retry with userfs.tar
USERFS_IMAGE=${USERFS_IMAGE%.gz}
if [ -f ${MOUNT_POINT}/${USERFS_IMAGE} ]
then
	wirma2hw wd timeout 300
	info "Erasing Userfs"
	# PR 1741
	flash_eraseall --scrub ${USERFS_MTD_PART} > /dev/null 2>&1
	info "Mount UserFS partition to be updated."
	mount -t yaffs2 ${USERFS_PART} ${MOUNT_POINT_TOBEUPDATED} > /dev/null 2>&1
	cd ${MOUNT_POINT_TOBEUPDATED} > /dev/null 2>&1 || error "'cd' problem."
	info "Programming Userfs..."
	tar xpf  ${MOUNT_POINT}/${USERFS_IMAGE}
	cd - > /dev/null 2>&1 || error "'cd' problem."
	sync
	umount -f ${MOUNT_POINT_TOBEUPDATED} > /dev/null 2>&1 || error "umount ${USERFS_PART}."
	info "New UserFS updated."
fi

# Check for enough space to install dotas
mount -t yaffs2 ${ROOTFS_PART} ${MOUNT_POINT_ROOTFS} > /dev/null 2>&1 || error "Unable to mount ${MOUNT_POINT_ROOTFS}"
ROOTFS_USE=`df | grep "${ROOTFS_PART}" | awk '{print $5}' | sed 's/%//'`

if [ ${ROOTFS_USE} -ge 95 ]
then
	wirma2hw wd timeout 300
	error "Rootfs is almost full, dump it and restore it"
	# Set quick led blinking
	echo klk-timer > "/sys/devices/platform/leds-gpio/leds:status-red/trigger"
	echo 50 > "/sys/devices/platform/leds-gpio/leds:status-red/delay_on"
	echo 50 > "/sys/devices/platform/leds-gpio/leds:status-red/delay_off"

	dump_rootfs ${MOUNT_POINT}/rdump_${KNET_ID}_${ROOTFS_USE}.tar.gz

	# Fix bad unmount of dump_rootfs
	cd /
	sync
	umount ${ROOTFS_PART}

	restore_rootfs
	# Restart Produsb
	return 1
fi


mount -t yaffs2 ${USERFS_PART} ${MOUNT_POINT_USERFS} > /dev/null 2>&1 || error "Unable to mount ${MOUNT_POINT_USERFS}"
mkdir -p ${DOTA_PATH}

cd ${DOTA_PATH}

# User Update
if [ -f ${MOUNT_POINT}/${UPDATE_FILE} ]
then
	ln -s ${MOUNT_POINT}/${UPDATE_FILE}
	need_dota=1

	mount -t yaffs2 ${RESCUEFS_PART} ${MOUNT_POINT_RESCUEFS}
	cp -f ${MOUNT_POINT}/${UPDATE_FILE} ${MOUNT_POINT_RESCUEFS}/${FS_RESCUE_UPDATE}
	sync
	umount ${MOUNT_POINT_RESCUEFS}
fi


#Check for misc dotas / custos
dotalist=`ls ${MOUNT_POINT}/dota_* ${MOUNT_POINT}/custo_* 2>/dev/null`
for dotafile in ${dotalist}
do
	[ -f ${dotafile} ] && ln -s ${dotafile}
	need_dota=1
done

cd /
sync
umount ${MOUNT_POINT_USERFS} > /dev/null 2>&1 || info "Unable to umount ${MOUNT_POINT_USERFS}"

wirma2hw wd timeout 300
[ ${need_dota} ] && dota

# SD CARD
if [ -f ${MOUNT_POINT}/${SDCARD_IMAGE:=sdcard.tar.gz} ]
then
	wirma2hw wd timeout 300
	mkdosfs ${SD_DEVICE}
	mount ${SD_DEVICE} ${MOUNT_POINT_TOBEUPDATED} > /dev/null 2>&1
   cd ${MOUNT_POINT_TOBEUPDATED}
	tar xzpf ${MOUNT_POINT}/${SDCARD_IMAGE}
	sync
	cd -
	umount -f ${MOUNT_POINT_TOBEUPDATED} > /dev/null 2>&1
fi

# C8051
if [ -f ${MOUNT_POINT}/${C8051_IMAGE} ]
then
	cp ${MOUNT_POINT}/${C8051_IMAGE} ${TMP_DIR}/${C8051_IMAGE}
	update_c8051 ${TMP_DIR}/${C8051_IMAGE}
	[ $? -eq 0 ] && echo "C8051 updated"
fi

# HUAWEI (find a .FWL file with MU509 string)
GSM_FW_FILE=`ls ${MOUNT_POINT}/ | grep ".FWL" | grep "MU509-B_UPDATE_"`
if [ -n "${GSM_FW_FILE}" ]
then
	cp ${MOUNT_POINT}/${GSM_FW_FILE} ${TMP_DIR}/${GSM_FW_FILE}
	update_huawei ${TMP_DIR}/${GSM_FW_FILE}
	[ $? -eq 0 ] && echo "HUAWEI GSM Firmware updated"
fi

# All was updated so move bootstrap for update on another board
[ -f ${MOUNT_POINT}/${BOOTSTRAP_IMAGE}.updated ] && mv ${MOUNT_POINT}/${BOOTSTRAP_IMAGE}.updated ${MOUNT_POINT}/${BOOTSTRAP_IMAGE}

# Remove special flags if any
fw_setenv bootargs_user

# Must return 0 to update produsb.log, produsb flag is always reset
return 0
