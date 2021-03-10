#!/bin/bash
# creates basic lxc container (based on alpine linux 3.10 + assumes 64 bit arch)
#   - provide: CONTAINER NAME
#   - optional: CONTAINER IP Address
#   - optional: PROVIDE HOST MOUNT DIR (defaults to /projects)
# example:
#   lxc-create-basic-container.sh C1 IP /my-projects
#
# notes:
#   This is specific for Ubuntu

# !! DOES NOT WORK !!



CONTAINER_IMAGE="ubuntu-minimal:20.04"
CONTAINER_NAME=$1
IP_ADDRESS="${2:DEFAULT_ASSIGNED_IP}"
CONTAINER_USER="ubuntu"
CONTAINER_USER_ID="1000"
CONTAINER_HOME_DIR="/home/ubuntu"
MOUNT_BASE_DIR="${3:-/projects}"

wait_until_container_ready() {
  while ! lxc info $CONTAINER_NAME | grep Status | grep $1; do echo "$CONTAINER_NAME still starting..."; sleep 1; done
}

lxc launch $CONTAINER_IMAGE $CONTAINER_NAME
wait_until_container_ready "Running"

# config container to have bash (alpine specific)
echo "Configuring $CONTAINER_NAME to have bash"
lxc exec $CONTAINER_NAME -- apt update
lxc exec $CONTAINER_NAME -- apt upgrade

# grant uid permissions & link project base code dir
lxc stop $CONTAINER_NAME
wait_until_container_ready "Stopped"

# map user
lxc config set $CONTAINER_NAME raw.idmap "both $UID 1000"
lxc config device add $CONTAINER_NAME project-dir disk source=$HOME$MOUNT_BASE_DIR path=$CONTAINER_HOME_DIR$MOUNT_BASE_DIR

# assign static ip
if [ $IP_ADDRESS != "DEFAULT_ASSIGNED_IP" ]; then
  lxc network attach lxdbr0 $CONTAINER_NAME eth0
  lxc config device set $CONTAINER_NAME eth0 ipv4.address $IP_ADDRESS
fi

# start container again
lxc start $CONTAINER_NAME
wait_until_container_ready "Running"

# add aliases
echo "adding bash aliases..."
lxc exec $CONTAINER_NAME -- sudo su -l $CONTAINER_USER_ID -- bash -c "touch ~/.bashrc"
lxc exec $CONTAINER_NAME -- sudo su -l $CONTAINER_USER_ID -- bash -c "echo \"#aliases\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME -- sudo su -l $CONTAINER_USER_ID -- bash -c "echo \"alias la='ls -la'\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME -- sudo su -l $CONTAINER_USER_ID -- bash -c "echo \"alias ll='ls -lh'\" >> ~/.bashrc"

echo "$CONTAINER_NAME is UP"
