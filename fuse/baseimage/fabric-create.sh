#!/bin/bash
#
# Starts a fabric with the given environment variables
#
# Sets the environment variables
#
if [ -z $FABRIC_USER ]; then
    export FABRIC_USER=admin
fi
if [ -z $FABRIC_PASSWD ]; then
    export FABRIC_PASSWD=admin
fi
if [ -z $SSH_PASSWD ]; then
    export SSH_PASSWD=admin
fi
if [ -z $ZOOKEEPER_PASSWD ]; then
    export ZOOKEEPER_PASSWD=${FABRIC_PASSWD}
fi

#
# Run standalone version of fuse
#
echo "Starting JBoss Fuse"
/opt/jboss/fuse/bin/fuse server & FUSE_SERVER=$!

#
# Wait until the container is available to run client commands
#
count=0
while :
do
	echo "Wait for container"
	/opt/jboss/fuse/bin/client "version"; return=$?
	if [ $return -eq 0 ]; then
		sleep 15
		break
	else
		sleep 5
		(( count++ ))
		echo "Failed to get client session " $count " times."
		if [ $count == 60 ]; then
			echo "Failed to get a client session after 5 minutes, fabric create failed"
			exit 1
		fi
	fi
done

# Create the fabric
/opt/jboss/fuse/bin/client "shell:source fabric-create.script"
sleep 10
sed -i "s/-XX:+UnsyncloadClass /-XX:+UnsyncloadClass\ -XX:MaxPermSize=512m -XX:+UseG1GC -XX:-UseAdaptiveSizePolicy -XX:+AggressiveOpts -XX:+CMSClassUnloadingEnabled /" /opt/jboss/fuse/instances/instance.properties
#/opt/jboss/fuse/bin/client "fabric:create --wait-for-provisioning --verbose --clean --bootstrap-timeout 60000 --new-user ${FABRIC_USER} --new-user-password ${FABRIC_PASSWD} --zookeeper-password ${ZOOKEEPER_PASSWD} --resolver localip"

#git clone http://${FABRIC_USER}:${FABRIC_PASSWD}@127.0.0.1:8181/git/fabric fabric_local
#cd fabric_local
#git checkout -b 1.1
#
#git commit -m "Configured fuse to wotk with settings.xml"
#git push
#cd -
#rm -rf fabric_local

# Add managed server using ssh commands
echo "Managed servers to create" ${MANAGED_HOSTS}
for host in ${MANAGED_HOSTS//,/ }
do
    hostname=${host^^}
    servicehost=${hostname}_SERVICE_HOST
    echo "Create managed server" $host with service hostname ${!servicehost}
    /opt/jboss/fuse/bin/client "container-create-ssh --host ${!servicehost} --user user --password ${SSH_PASSWD} ${host}"
done

if [ -z $MANAGED_HOSTS ]; then
    echo Admin server is not startet with managed hosts
fi

# Wait for fuse to end
echo Fuse Fabric Server is ready for requests
wait $FUSE_SERVER