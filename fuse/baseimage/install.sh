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

echo "
timeout=20
retries=5
" >> /etc/yum.conf

yum -y update
#yum -y install openssh-server passwd htop mtr nano which telnet unzip openssh-server sudo openssh-clients wget curl tar iptables perl git bash-completion iproute mc
yum -y install git
yum clean all -y
rm -rf /var/cache/yum

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

unzip -q jboss-fuse-full-6.2.1.redhat-084.zip
mv jboss-fuse-6.2.1.redhat-084 fuse
rm jboss-fuse-full-6.2.1.redhat-084.zip

rm fuse/bin/*.bat fuse/bin/start fuse/bin/stop fuse/bin/status fuse/bin/patch

# Lets remove some bits of the distro which just add extra weight in a docker image.
rm -rf fuse/extras
rm -rf fuse/quickstarts

#mv -f io.fabric8.datastore.cfg fuse/etc
#mv -f io.fabric8.maven.cfg fuse/etc
#mv -f org.ops4j.pax.url.mvn.cfg fuse/etc
mv -f users.properties fuse/etc
mv -f fabric-create.sh fuse/bin
mv -f fabric-join.sh fuse/bin
mv -f settings.xml fuse

chmod a+x fuse/bin/*

#
# Let the karaf container name/id come from setting the FUSE_KARAF_NAME && FUSE_RUNTIME_ID env vars
# default to using the container hostname.
sed -i -e 's/environment.prefix=FABRIC8_/environment.prefix=FUSE_/' fuse/etc/system.properties
sed -i -e '/karaf.name = root/d' fuse/etc/system.properties
sed -i -e '/runtime.id=/d' fuse/etc/system.properties
echo '
if [ -z "$FUSE_KARAF_NAME" ]; then 
  export FUSE_KARAF_NAME="$HOSTNAME"
fi
if [ -z "$FUSE_RUNTIME_ID" ]; then 
  export FUSE_RUNTIME_ID="$FUSE_KARAF_NAME"
fi

export KARAF_OPTS="-Dkaraf.name=${FUSE_KARAF_NAME} -Druntime.id=${FUSE_RUNTIME_ID}"
'>> fuse/bin/setenv

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
sed -i -e 's/karaf.delay.console=true/karaf.delay.console=false/' fuse/etc/config.properties 
echo '
# Root logger
log4j.rootLogger=INFO, stdout, osgi:*VmLogAppender
log4j.throwableRenderer=org.apache.log4j.OsgiThrowableRenderer

# CONSOLE appender not used by default
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d{ABSOLUTE} | %-5.5p | %-16.16t | %-32.32c{1} | %X{bundle.id} - %X{bundle.name} - %X{bundle.version} | %m%n
' > fuse/etc/org.ops4j.pax.logging.cfg

echo '
bind.address=0.0.0.0
karaf.shell.init.script=${karaf.etc}/shell.init.script
'>> fuse/etc/system.properties

sed -i 's/-Dcom.sun.management.jmxremote/-Dcom.sun.management.jmxremote -XX:+UseG1GC -XX:-UseAdaptiveSizePolicy -XX:+AggressiveOpts -XX:+CMSClassUnloadingEnabled/' fuse/bin/karaf

rm /opt/jboss/install.sh