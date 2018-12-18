#!/usr/bin/env bash
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
if [ -z $FUSE_KARAF_NAME ]; then
    export FUSE_KARAF_NAME=${HOSTNAME}
fi
if [ -z "$FUSE_RUNTIME_ID" ]; then
  export FUSE_RUNTIME_ID=$FUSE_KARAF_NAME
fi

echo "Starting JBoss Fuse"
/opt/jboss/jboss-fuse/bin/fuse server & FUSE_SERVER=$!

count=0
while :
do
	echo "Wait for container"
	/opt/jboss/jboss-fuse/bin/client "version"; return=$?
	if [[ $return -eq 0 ]]; then
		sleep 15
		break
	else
		sleep 5
		(( count++ ))
		echo "Failed to get client session " $count " times."
		if [[ $count == 60 ]]; then
			echo "Failed to get a client session after 5 minutes, fabric create failed"
			exit 1
		fi
	fi
done

if [[ -f ".log" ]]
then
	echo "Fabric already configured"
	find /opt/jboss/jboss-fuse/instances/ -maxdepth 3 -type f -executable -name 'start' -exec {} \;
else
#    /opt/jboss/jboss-fuse/bin/client -v "fabric:create --wait-for-provisioning --verbose --new-user ${FABRIC_USER} --new-user-password ${FABRIC_PASSWD} --zookeeper-password ${ZOOKEEPER_PASSWD} --resolver localip"
    sleep 30
    ( echo "cat <<EOF" ; cat /opt/jboss/jboss-fuse/fabric-create.script ; echo EOF ) | sh > /opt/jboss/jboss-fuse/fabric-create.tmp
    cat /opt/jboss/jboss-fuse/fabric-create.tmp > /opt/jboss/jboss-fuse/fabric-create.script
    echo 'Executing script'
    /opt/jboss/jboss-fuse/bin/client -v -r 10 -d 10 "shell:source fabric-create.script"
    echo 'Script was executed'
    rm -f /opt/jboss/jboss-fuse/fabric-*.*
    touch .log
    echo '' > /opt/jboss/jboss-fuse/etc/users.properties
fi

echo Fuse Fabric Server is ready for requests
wait $FUSE_SERVER