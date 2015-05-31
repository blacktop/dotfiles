# Creating Windows VM Notes

 [Virtio ISO](https://fedoraproject.org/wiki/Windows_Virtio_Drivers#Direct_download)

## Install KVM
```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```
If you get a 0 back fix your VM/system to support VMs.
```bash
$ sudo apt-get install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils qemu-system
```
Make sure it worked by running:
```bash
$ virsh -c qemu:///system list
```
## Install Virtual Machine Manager
```bash
$ sudo apt-get install virt-manager ubuntu-virt virt-top virt-what
```

#### Trouble Shooting
[VM starts paused](http://porkrind.org/missives/libvirt-based-qemu-vm-pausing-by-itself/)

#### references
 - [kvm_windows_xp_install_openstack](http://unicornclouds.telegr.am/blog_posts/kvm_windows_xp_install_openstack)
 - [creating-windows-xp-image-for-openstack](http://www.yaomuyang.com/2015/03/27/creating-windows-xp-image-for-openstack)
 - [create-windows-openstack-images](http://www.cloudbase.it/create-windows-openstack-images)
 - [porting-windows-to-openstack](https://poolsidemenace.wordpress.com/2011/06/16/porting-windows-to-openstack/)
 - [openstack-windows-image](http://docs.openstack.org/image-guide/content/windows-image.html)
 - [another-one](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Virtualization_Host_Configuration_and_Guest_Installation_Guide/form-Virtualization_Host_Configuration_and_Guest_Installation_Guide-Para_virtualized_drivers-Mounting_the_image_with_virt_manager.html)
