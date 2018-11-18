# Use latest jboss/base-jdk:8 image as the base
FROM jboss/base-jdk:8

MAINTAINER Boris Velichko <boris86496@gmail.com>

USER root

# Set the FUSE_VERSION env variable
ENV FUSE_VERSION 6.2.1.0.redhat-084 \
    MAVEN_HOME /usr/share/maven \
	FUSE_PUBLIC_OPENWIRE_PORT 61616 \
	FUSE_PUBLIC_MQTT_PORT 1883 \
	FUSE_PUBLIC_AMQP_PORT 5672 \
	FUSE_PUBLIC_STOMP_PORT 61613 \
	FUSE_PUBLIC_OPENWIRE_SSL_PORT 61617 \
	FUSE_PUBLIC_MQTT_SSL_PORT 8883 \
	FUSE_PUBLIC_AMQP_SSL_PORT 5671 \
	FUSE_PUBLIC_STOMP_SSL_PORT 61614 \
	FUSE_PUBLIC_ZOOKEEPER_PORT 2181

# Install fuse in the image.
COPY install.sh io.fabric8.datastore.cfg io.fabric8.maven.cfg org.ops4j.pax.url.mvn.cfg settings.xml users.properties fabric-create.sh fabric-join.sh jboss-fuse-full-6.2.1.redhat-084.zip /opt/jboss/
RUN /opt/jboss/install.sh

EXPOSE 8181 8101 1099 44444 61616 1883 5672 61613 61617 8883 5671 61614 2181

#
# The following directories can hold config/data, so lets suggest the user
# mount them as volumes.
VOLUME /opt/jboss/fuse/data
#VOLUME /opt/jboss/fuse/system
VOLUME /opt/jboss/fuse/instances

# lets default to the jboss-fuse dir so folks can more easily navigate to around the server install
WORKDIR /opt/jboss/fuse
CMD /opt/jboss/fuse/bin/fuse server