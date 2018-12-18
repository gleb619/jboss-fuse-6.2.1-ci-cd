#!/bin/bash
#
# We configure the distro, here before it gets imported into docker
# to reduce the number of UFS layers that are needed for the Docker container.
#

# Adjust the following env vars if needed.
#FUSE_ARTIFACT_ID=jboss-fuse-karaf
#FUSE_DISTRO_URL=https://maven.repository.redhat.com/ga/org/jboss/fuse/${FUSE_ARTIFACT_ID}/${FUSE_VERSION}/${FUSE_ARTIFACT_ID}-${FUSE_VERSION}.zip

# Lets fail fast if any command in this script does succeed.
set -e

export INSTANCE_ID="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')0d$(date +%Y%m%d)"
#
# Lets switch to the /opt/jboss dir
#
cd /opt/jboss
echo $INSTANCE_ID > .instance

mkdir test
cd test
git init
git config --global user.email "${INSTANCE_ID}@example.com"
git config --global user.name "${INSTANCE_ID}"
cd -
rm -rf test

# Download and extract the distro
#curl -O ${FUSE_DISTRO_URL}
#jar -xvf ${FUSE_ARTIFACT_ID}-${FUSE_VERSION}.zip
#rm ${FUSE_ARTIFACT_ID}-${FUSE_VERSION}.zip

# Install maven and do some tests
#curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz | tar xzf - -C /usr/share
#mv /usr/share/apache-maven-3.3.9 /usr/share/maven
#ls -lash /usr/share/maven/conf
#ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
#mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
#cd my-app
#mvn clean package -q

#git add .
#git commit -m "Initial" -q
#cd ..
#rm -rf my-app

unzip -q jboss-fuse-karaf-6.3.0.redhat-187.zip
mv jboss-fuse-6.3.0.redhat-187 fuse
chmod a+x fuse/bin/*

#mv -f io.fabric8.datastore.cfg fuse/etc
#mv -f io.fabric8.maven.cfg fuse/etc
#mv -f org.ops4j.pax.url.mvn.cfg fuse/etc
mv -f users.properties fuse/etc
mv -f fabric-create.sh fuse/bin
mv -f fabric-join.sh fuse/bin
mv -f settings.xml fuse
mv -f fabric-join.script fuse
mv -f fabric-create.script fuse

mkdir -p /opt/jboss/fuse/kahadb

#
# Let the karaf container name/id come from setting the FUSE_KARAF_NAME && FUSE_RUNTIME_ID env vars
# default to using the container hostname.
#sed -i -e 's/environment.prefix=FABRIC8_/environment.prefix=FUSE_/' fuse/etc/system.properties
sed -i -e 's/karaf.name = root/karaf.name = ${docker.karaf.name}/' fuse/etc/system.properties
sed -i -e 's/activemq.host = localhost/activemq.host = 0.0.0.0/' fuse/etc/system.properties
sed -i -e 's/${data}\/kahadb/\/opt\/jboss\/fuse\/kahadb/' fuse/etc/activemq.xml
echo 'bind.address = 0.0.0.0
'>> fuse/etc/system.properties

echo '
if [ -z "$FUSE_KARAF_NAME" ]; then 
  export FUSE_KARAF_NAME="$HOSTNAME"
fi
if [ -z "$FUSE_RUNTIME_ID" ]; then 
  export FUSE_RUNTIME_ID="$FUSE_KARAF_NAME"
fi

export KARAF_OPTS="-Dnexus.addr=${NEXUS_PORT_8081_TCP_ADDR} -Dnexus.port=${NEXUS_PORT_8081_TCP_PORT} $KARAF_OPTS"
export KARAF_OPTS="-Ddocker.karaf.name=${FUSE_KARAF_NAME} -Djava.net.preferIPv4Stack=true $KARAF_OPTS"
'>> fuse/bin/setenv

sed -i -e 's/fuseearlyaccess$/&,http:\/\/${nexus.addr}:${nexus.port}\/repository\/releases@id=nexus.release.repo,  http:\/\/${nexus.addr}:${nexus.port}\/repository\/snapshots@id=nexus.snapshot.repo@snapshots/' fuse/etc/org.ops4j.pax.url.mvn.cfg

#
# Move the bundle cache and tmp directories outside of the data dir so it's not persisted between container runs
#
mv fuse/data/tmp fuse/tmp
echo '
org.osgi.framework.storage=${karaf.base}/tmp/cache
'>> fuse/etc/config.properties

sed -i -e 's/-Djava.io.tmpdir="$KARAF_DATA\/tmp"/-Djava.io.tmpdir="$KARAF_BASE\/tmp"/' fuse/bin/karaf
sed -i -e 's/-Djava.io.tmpdir="$KARAF_DATA\/tmp"/-Djava.io.tmpdir="$KARAF_BASE\/tmp"/' fuse/bin/fuse
sed -i -e 's/-Djava.io.tmpdir="$KARAF_DATA\/tmp"/-Djava.io.tmpdir="$KARAF_BASE\/tmp"/' fuse/bin/client
sed -i -e 's/-Djava.io.tmpdir="$KARAF_DATA\/tmp"/-Djava.io.tmpdir="$KARAF_BASE\/tmp"/' fuse/bin/admin
sed -i -e 's/${karaf.data}\/generated-bundles/${karaf.base}\/tmp\/generated-bundles/' fuse/etc/org.apache.felix.fileinstall-deploy.cfg

# lets remove the karaf.delay.console=true to disable the progress bar
sed -i -e 's/karaf.delay.console=true/karaf.delay.console=false/g' fuse/etc/config.properties
sed -i -e 's/karaf.delay.console=true/karaf.delay.console=false/' fuse/etc/custom.properties
echo '
# Root logger
log4j.rootLogger=INFO, stdout, osgi:*VmLogAppender
log4j.throwableRenderer=org.apache.log4j.OsgiThrowableRenderer

# CONSOLE appender not used by default
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d{ABSOLUTE} | %-5.5p | %-16.16t | %-32.32c{1} | %X{bundle.id} - %X{bundle.name} - %X{bundle.version} | %m%n
' > fuse/etc/org.ops4j.pax.logging.cfg

sed -i 's/-Dcom.sun.management.jmxremote/-Dcom.sun.management.jmxremote -XX:+UseG1GC -XX:-UseAdaptiveSizePolicy -XX:+AggressiveOpts -XX:+CMSClassUnloadingEnabled/' fuse/bin/karaf

rm -rf fuse/extras
rm -rf fuse/quickstarts
rm jboss-fuse-karaf-6.3.0.redhat-187.zip
rm fuse/bin/*.bat fuse/bin/start fuse/bin/stop fuse/bin/status fuse/bin/patch
rm -rf fuse/extras
rm -rf fuse/quickstarts
rm /opt/jboss/install.sh
