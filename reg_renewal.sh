#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/config
export  CACHEDIR LETSDIR REGDIR DOMAIN
if [[ -f /gluster/@/etc/letsencrypt/live/$DOMAIN/restart ]]
then
    # scale down to zero 
    docker service scale reg_registry=0
    # scale down to zero
    docker service scale reg_registry=1
    # remove restart file
    rm /gluster/@/etc/letsencrypt/live/$DOMAIN/restart
fi
