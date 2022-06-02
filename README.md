# bash-scripts
Various bash scripts tools used to save time.

# Bash

## Recall command
Sometimes you forget, just decribe the command in the top of the script.

Add the ```bash/recall-command.sh``` to your path.
>recall-command

# LXC node container

## Creating node container
Creates container based on Alpine linux, super lightweight ;)
Will mount project source code dir on host in container.
>lxc/lxc-create-node-container.sh CONTAINER_NAME IP_ADDRESS
\
e.g. ```lxc/lxc-create-node-container.sh CONTAINER-NAME 10.104.71.2```

## Create react container code project
Creates react code container (based on node container).
Edit code on the host. Compile, build and run node in the container.
Last option is defaulted to install additonal react dependencies, specify false if you don't need them.

>lxc/lxc-create-react-code-project-container.sh CONTAINER_NAME IP_ADDRESS PROJECT_CODE REACT_APP_NAME [false]
\
e.g. ```lxc/lxc-create-react-code-project-container.sh CONTAINER-NAME 10.237.245.10 /project/code my-cool-app```

Use ```npm start``` inside the container (after react project has been created).

## Issues
Sometimes when hacking on LXC/LXD containers...
When a container can't be deleted due to ZFS error message "Error: Failed to destroy ZFS filesystem:"
1. Stop the container ```lxc stop CONTAINER```
2. List the ZFS pools ```zfs list```
3. rename the offending conatainer pool ```zfs rename POOL POOL-failed``` (just suffix with -failed)
4. Delete the container ```lxc delete CONTAINER```
5. Delete the ZFS pool ```sudo zfs destroy POOL-failed``` (take care doing this)    

## Node

All applies to the node dir. 


### Run simple node webserver

Need to install ```npm install connect serve-static```
Advisable to do this in a container (see LXC scripts)

* ```run-webserver.sh DIR``` (will invoke webserver.js) where DIR is the source dir you want to serve files from (not relative)
 
