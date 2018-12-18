#!/bin/sh
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
if [ -z $ZOOKEEPER_PASSWD ]; then
    export ZOOKEEPER_PASSWD=${FABRIC_PASSWD}
fi
if [ -z $FABRIC_SERVER_NAME ]; then
    export FABRIC_SERVER_NAME=fuseadmin
fi

#
# Run standalone version of fuse
#
echo "Starting JBoss Fuse"
/opt/jboss/jboss-fuse/bin/fuse server & FUSE_SERVER=$!

sleep 200
#
# Wait until the container is available to run client commands
#
count=0
while :
do
	echo "Wait for container"
	/opt/jboss/jboss-fuse/bin/client "version"; return=$?
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

if [ -f ".log" ]
then
	echo "Fabric already configured"
	find /opt/jboss/jboss-fuse/instances/ -maxdepth 3 -type f -executable -name 'start' -exec {} \;
else
    sleep $[($RANDOM % 20) + 40]s

    attempt_counter=0
    max_attempts=15

    until $(curl --output /dev/null --silent --head --fail http://${FABRIC_USER}:${FABRIC_PASSWD}@${FABRIC_SERVER_NAME}:8181/jolokia); do
        if [ ${attempt_counter} -eq ${max_attempts} ];then
          echo "Max attempts reached"
          exit 1
        fi

        printf '.'
        attempt_counter=$(($attempt_counter+1))
        sleep 5
    done

    /opt/jboss/jboss-fuse/bin/client -v "fabric:join --resolver localip --zookeeper-password ${ZOOKEEPER_PASSWD} ${FABRIC_SERVER_NAME} ${FUSE_KARAF_NAME}"
    sleep 30
    /opt/jboss/jboss-fuse/bin/client -v "version-list"

    # Join the fabric
    ( echo "cat <<EOF" ; cat /opt/jboss/jboss-fuse/fabric-join.script ; echo EOF ) | sh > /opt/jboss/jboss-fuse/fabric-join.tmp
    cat /opt/jboss/jboss-fuse/fabric-join.tmp > /opt/jboss/jboss-fuse/fabric-join.script
    echo 'Executing script'
    /opt/jboss/jboss-fuse/bin/client -v -r 10 -d 10 "shell:source fabric-join.script"
    echo 'Script was executed'
    rm -f /opt/jboss/jboss-fuse/fabric-*.*
    touch .log
    echo '' > /opt/jboss/jboss-fuse/etc/users.properties
    #rm -rf /opt/jboss/jboss-fuse/fabric-join.*
fi

# Wait for fuse to end
echo Fuse Fabric Server ready for requests
wait $FUSE_SERVER