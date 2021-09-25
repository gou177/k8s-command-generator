# unmount
umount /{}

# remove lv
lvremove /dev/mapper/vg0-{}

# list segments 
pvs -v --segments /dev/sda4

# move pv
sudo pvmove --alloc anywhere /dev/sda4:17577-28311

# resize
pvresize --setphysicalvolumesize 54GiB /dev/sda4

# print
pvdisplay 

# partied
parted /dev/sda
 >>>
    # resize
    resizepart 4 60GB

    # create new partition
    mkpart logical 60GB 100%


# ceph cleanup

export DISK="/dev/sda5"
sgdisk --zap-all $DISK
blkdiscard $DISK
