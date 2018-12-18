#!/bin/bash
#
# We configure the distro, here before it gets imported into docker
# to reduce the number of UFS layers that are needed for the Docker container.
#

# Adjust the following env vars if needed.
# Lets fail fast if any command in this script does succeed.
set -e

#
# Lets switch to the /opt/jboss dir
#
cd /opt/jboss

# Download and extract the distro

unzip -q jboss-fuse-karaf-6.3.0.redhat-187.zip
mv jboss-fuse-6.3.0.redhat-187 jboss-fuse
chmod a+x jboss-fuse/bin/*

mv fabric-join.script /opt/jboss/jboss-fuse/
mv fabric-join.sh /opt/jboss/jboss-fuse/bin/
mv fabric-create.script /opt/jboss/jboss-fuse/
mv fabric-create.sh /opt/jboss/jboss-fuse/bin/

#chmod a+x jboss-fuse/bin/*
rm jboss-fuse/bin/*.bat jboss-fuse/bin/start jboss-fuse/bin/stop jboss-fuse/bin/status jboss-fuse/bin/patch


# Lets remove some bits of the distro which just add extra weight in a docker image.
rm -rf jboss-fuse/extras
rm -rf jboss-fuse/quickstarts
rm -rf jboss-fuse/docs
rm -rf jboss-fuse-karaf-6.3.0.redhat-187.zip

#sed -i -e 's/environment.prefix=FABRIC8_/environment.prefix=FUSE_/' jboss-fuse/etc/system.properties

#sed -i -e '/karaf.name = root/d' jboss-fuse/etc/system.properties
#sed -i -e '/runtime.id=/d' jboss-fuse/etc/system.properties
sed -i -e 's/karaf.name = root/karaf.name = ${docker.karaf.name}/' jboss-fuse/etc/system.properties
#sed -i -e 's/karaf.name = root/karaf.name = ${docker.runtime.id}/' jboss-fuse/etc/system.properties

# enable a link to a local nexus container
echo '
if [ -z "$FUSE_KARAF_NAME" ]; then
  export FUSE_KARAF_NAME="$HOSTNAME"
fi
if [ -z "$FUSE_RUNTIME_ID" ]; then
  export FUSE_RUNTIME_ID="$FUSE_KARAF_NAME"
fi

export KARAF_OPTS="-Ddocker.karaf.name=${FUSE_KARAF_NAME} -Dnexus.addr=${NEXUS_PORT_8081_TCP_ADDR} -Dnexus.port=${NEXUS_PORT_8081_TCP_PORT} -Djava.net.preferIPv4Stack=true $KARAF_OPTS"
'>> jboss-fuse/bin/setenv
# Add the nexus repos (uses the nexus link)
sed -i -e 's/fuseearlyaccess$/&,http:\/\/${nexus.addr}:${nexus.port}\/repository\/releases@id=nexus.release.repo,  http:\/\/${nexus.addr}:${nexus.port}\/repository\/snapshots@id=nexus.snapshot.repo@snapshots/' \
  jboss-fuse/etc/org.ops4j.pax.url.mvn.cfg

#bind AMQ to all IP addresses
sed -i -e 's/activemq.host = localhost/activemq.host = 0.0.0.0/' jboss-fuse/etc/system.properties
mkdir -p /opt/jboss/jboss-fuse/kahadb
sed -i -e 's/${data}\/kahadb/\/opt\/jboss\/jboss-fuse\/kahadb/' jboss-fuse/etc/activemq.xml

# lets remove the karaf.delay.console=true to disable the progress bar
sed -i -e 's/karaf.delay.console=true/karaf.delay.console=false/g' jboss-fuse/etc/config.properties
sed -i -e 's/karaf.delay.console=true/karaf.delay.console=false/' jboss-fuse/etc/custom.properties

#enable the console logger
echo '
# Root logger
log4j.rootLogger=INFO, stdout, osgi:*VmLogAppender
log4j.throwableRenderer=org.apache.log4j.OsgiThrowableRenderer

# CONSOLE appender not used by default
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d{ABSOLUTE} | %-5.5p | %-16.16t | %-32.32c{1} | %X{bundle.id} - %X{bundle.name} - %X{bundle.version} | %m%n
' > jboss-fuse/etc/org.ops4j.pax.logging.cfg

echo '
bind.address = 0.0.0.0
'>> jboss-fuse/etc/system.properties
echo '
admin=admin,admin,manager,viewer,Operator, Maintainer, Deployer, Auditor, Administrator, SuperUser
' >> jboss-fuse/etc/users.properties

rm /opt/jboss/install.sh
