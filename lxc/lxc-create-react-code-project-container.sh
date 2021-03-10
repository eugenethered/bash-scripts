#!/bin/bash
# creates react code project lxc container (depends on lxc-create-node-container.sh)
#	  - provide: IP ADDRESSS
#   - provide: CONTAINER NAME
#   - provide: PROJECT CODE DIR (relative path after container home dir)
#   - default: REACT_INSTALL_COMMON_DEPS change to false if you don't want additonal react deps
# notes:
#   create-react-app . (not working due to conflicts, so using a work around)
#   meant to be used once (when trying on existing source code with existing react project, this will fail)
#   REACT_INSTALL_COMMON_DEPS - will install base react dependencies

CONTAINER_USER_ID="1000"
CONTAINER_USER="contain"
CONTAINER_GROUP="contain"
CONTAINER_NAME=$1
IP_ADDRESS=$2
CONTAINER_HOME_DIR="/home/contain"
PROJECT_BASE_DIR=$3
REACT_PROJECT_NAME=$4
REACT_INSTALL_COMMON_DEPS="${5:-true}"

./lxc-create-node-container.sh $CONTAINER_NAME $IP_ADDRESS

echo "node container created, configuring react project..."
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "cd $CONTAINER_HOME_DIR$PROJECT_BASE_DIR; npx create-react-app $REACT_PROJECT_NAME"

# adding common dependencies (redux, axios, router) - by default
if [ $REACT_INSTALL_COMMON_DEPS = true ]; then
  echo "creating common react project dependencies..."
  lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "cd $CONTAINER_HOME_DIR$PROJECT_BASE_DIR/$REACT_PROJECT_NAME; npm install --save redux react-redux"
  lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "cd $CONTAINER_HOME_DIR$PROJECT_BASE_DIR/$REACT_PROJECT_NAME; npm install --save axios"
  lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "cd $CONTAINER_HOME_DIR$PROJECT_BASE_DIR/$REACT_PROJECT_NAME; npm install --save redux-thunk"
  lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "cd $CONTAINER_HOME_DIR$PROJECT_BASE_DIR/$REACT_PROJECT_NAME; npm install --save react-router react-router-dom"
fi

# when mounting host to container (do as #, newly created react project could have interesting permissions, stabalize these)
echo "ensuring permissions are consistent..."
lxc exec $CONTAINER_NAME -- bash -c "chown -R $CONTAINER_USER:$CONTAINER_GROUP $CONTAINER_HOME_DIR$PROJECT_BASE_DIR/$REACT_PROJECT_NAME"

# move newly "minted" react project files to original project source code
echo "react project created, now moving specific files up..."
for f in '.gitignore' 'package.json' 'package-lock.json' 'public' 'src' 'node_modules'; do
  lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "mv $CONTAINER_HOME_DIR$PROJECT_BASE_DIR/$REACT_PROJECT_NAME/${f} $CONTAINER_HOME_DIR$PROJECT_BASE_DIR/"
done

echo "cleaning up react project..."
lxc exec $CONTAINER_NAME --user $CONTAINER_USER_ID -- bash -c "rm -fr $CONTAINER_HOME_DIR$PROJECT_BASE_DIR/$REACT_PROJECT_NAME";

echo "Done react project container created!"
