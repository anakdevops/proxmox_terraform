#!/bin/bash

# Define variables
VMID=8001
TEMPLATE_NAME="ubuntu-cloud-init"
CLONE_ID=135
CLONE_NAME="anak-devops"
IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMAGE_NAME="noble-server-cloudimg-amd64.img"
LOG_FILE="finish.log"

# Log start time
echo "Script started at $(date)" >> $LOG_FILE

# Download the image file, removing any existing file first
if [ -f $IMAGE_NAME ]; then
    echo "Removing existing image file $IMAGE_NAME..." >> $LOG_FILE
    rm -f $IMAGE_NAME
fi

echo "Downloading image file from $IMAGE_URL..." >> $LOG_FILE
wget $IMAGE_URL >> $LOG_FILE 2>&1

# Check if the download was successful
if [ ! -f $IMAGE_NAME ]; then
    echo "Failed to download the image file." >> $LOG_FILE
    exit 1
fi

# Create the VM with the specified memory, cores, and name
echo "Creating VM $VMID..." >> $LOG_FILE
qm create $VMID --memory 2048 --cores 2 --name $TEMPLATE_NAME --net0 virtio,bridge=vmbr0 >> $LOG_FILE 2>&1

# Import the disk image to local-lvm storage
echo "Importing disk image..." >> $LOG_FILE
qm disk import $VMID $IMAGE_NAME local-lvm >> $LOG_FILE 2>&1

# Set the SCSI hardware and attach the imported disk
echo "Configuring SCSI hardware and disk..." >> $LOG_FILE
qm set $VMID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$VMID-disk-0 >> $LOG_FILE 2>&1

# Configure the cloud-init drive
echo "Configuring cloud-init drive..." >> $LOG_FILE
qm set $VMID --ide2 local-lvm:cloudinit >> $LOG_FILE 2>&1

# Set the VM to boot from the SCSI disk
echo "Configuring boot options..." >> $LOG_FILE
qm set $VMID --boot c --bootdisk scsi0 >> $LOG_FILE 2>&1

# Configure serial port and VGA
echo "Configuring serial port and VGA..." >> $LOG_FILE
qm set $VMID --serial0 socket --vga serial0 >> $LOG_FILE 2>&1

# Convert the VM to a template
echo "Converting VM to template..." >> $LOG_FILE
qm template $VMID >> $LOG_FILE 2>&1

# Clone the template to create a new VM
echo "Cloning the template to create new VM $CLONE_ID..." >> $LOG_FILE
qm clone $VMID $CLONE_ID --name $CLONE_NAME --full >> $LOG_FILE 2>&1

# Log completion time
echo "Script completed at $(date)" >> $LOG_FILE
