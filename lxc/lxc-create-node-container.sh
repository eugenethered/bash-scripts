#!/bin/bash
# creates node ready lxc container (based on alpine linux 3.13 + assumes 64 bit arch)
#   - provide: CONTAINER NAME
#   - provide: IP ADDRESSS (static IP assumes on eth0 binded to bridge lxdbr0)
#   - optional: PROVIDE HOST PROJECT DIR (base dir)
# example:
#   lxc-create-node-container.sh C1 10.192.142.10 /project-dir
#
# notes:
#   Alpine Linux uses busybox, tools like ash (not bash) see - https://busybox.net/
#   Project dir must start with / - this is relative to both host + container dir's

CONTAINER_IMAGE="alpine/3.13/amd64"
CONTAINER_NAME=$1
IP_ADDRESS="${2:DEFAULT_ASSIGNED_IP}"
CONTAINER_USER="contain"
CONTAINER_GROUP="contain"
CONTAINER_USER_ID="1000"
CONTAINER_HOME_DIR="/home/contain"
PROJECT_BASE_DIR="${3:-/projects}"
NODE_VERISION="v16.0.0"
NODE_TAR_FILE="node-$NODE_VERISION-linux-x64.tar.xz"
NODE_DOWNLOAD_URL="https://nodejs.org/dist/$NODE_VERISION/$NODE_TAR_FILE"

wait_until_container_ready() {
  while ! lxc info $CONTAINER_NAME | grep Status | grep $1; do echo "$CONTAINER_NAME still starting..."; sleep 1; done
}

lxc launch images:$CONTAINER_IMAGE $CONTAINER_NAME
wait_until_container_ready "Running"

# config container to have bash (alpine specific)
echo "Configuring $CONTAINER_NAME to have bash"
lxc exec $CONTAINER_NAME -- apk update
lxc exec $CONTAINER_NAME -- apk upgrade
lxc exec $CONTAINER_NAME -- apk add bash

# add specific container user + group (mapped to raw.idmap)
lxc exec $CONTAINER_NAME -- ash -c "adduser -D -h $CONTAINER_HOME_DIR -u $CONTAINER_USER_ID -g $CONTAINER_GROUP -s /bin/bash $CONTAINER_USER"

# grant uid permissions & link project base code dir
lxc stop $CONTAINER_NAME
wait_until_container_ready "Stopped"

# map user
lxc config set $CONTAINER_NAME raw.idmap "both $UID 1000"
lxc config device add $CONTAINER_NAME project-dir disk source=$HOME$PROJECT_BASE_DIR path=$CONTAINER_HOME_DIR$PROJECT_BASE_DIR

# assign static ip
if [ $IP_ADDRESS != "DEFAULT_ASSIGNED_IP" ]; then
  lxc network attach lxdbr0 $CONTAINER_NAME eth0
  lxc config device set $CONTAINER_NAME eth0 ipv4.address $IP_ADDRESS
fi

# start container again
lxc start $CONTAINER_NAME
wait_until_container_ready "Running"

# config container to have wget + nodejs (alpine specific + update already happened above)
echo "Configuring $CONTAINER_NAME to have  wget + nodejs + npm (including npx)"
lxc exec $CONTAINER_NAME -- apk add ca-certificates wget nodejs npm

# add aliases
echo "adding bash aliases..."
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "touch ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"# general\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"alias la='ls -la'\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"alias ll='ls -lh'\" >> ~/.bashrc"
# add project specific alias
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"# projects\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"HOME='$CONTAINER_HOME_DIR'\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"PROJECT_HOME=\$HOME$PROJECT_BASE_DIR\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \" \" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"alias project.current='cd $PROJECT_HOME'\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"alias pc=\${BASH_ALIASES[project.current]}\" >> ~/.bashrc"
# add npm specific alias
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"# npm\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"alias ns='npm start'\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"alias nt='npm run test'\" >> ~/.bashrc"
# add default dir (on entering container)
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"# default dir\" >> ~/.bashrc"
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "echo \"cd \$PROJECT_HOME\" >> ~/.bashrc"

echo "$CONTAINER_NAME is UP with IP $IP_ADDRESS"
