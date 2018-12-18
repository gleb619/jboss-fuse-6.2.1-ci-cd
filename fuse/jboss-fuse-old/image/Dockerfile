FROM jboss/base-jdk:8

MAINTAINER Raphael Parree <rparree@edc4it.com>

# If the container is launched with re-mapped ports, these ENV vars should
# be set to the remapped values.
ENV FUSE_PUBLIC_OPENWIRE_PORT 61616 \
    FUSE_PUBLIC_MQTT_PORT 1883 \
    FUSE_PUBLIC_AMQP_PORT 5672 \
    FUSE_PUBLIC_STOMP_PORT 61613 \
    FUSE_PUBLIC_OPENWIRE_SSL_PORT 61617 \
    FUSE_PUBLIC_MQTT_SSL_PORT 8883 \
    FUSE_PUBLIC_AMQP_SSL_PORT 5671 \
    FUSE_PUBLIC_STOMP_SSL_PORT 61614

COPY jboss-fuse-karaf-6.3.0.redhat-187.zip \
    fabric-join.script \
    fabric-join.sh \
    fabric-create.script \
    fabric-create.sh \
    install.sh \
    /opt/jboss/

#USER root

RUN /opt/jboss/install.sh

#USER jboss

EXPOSE 1099 2181 8101 8181 9300 9301 44444 61616 1883 5672 61613 61617 8883 5671 61614 18000-18005 19000-19005

#VOLUME /opt/jboss/jboss-fuse/bin
#VOLUME /opt/jboss/jboss-fuse/etc
#VOLUME /opt/jboss/jboss-fuse/kahadb
#VOLUME /opt/jboss/jboss-fuse/deploy

# Maybe
#VOLUME /opt/jboss/jboss-fuse/data
#VOLUME /opt/jboss/jboss-fuse/kahadb
#VOLUME /opt/jboss/jboss-fuse/instances

# lets default to the jboss-fuse dir so folks can more easily navigate to around the server install
WORKDIR /opt/jboss/jboss-fuse
CMD /opt/jboss/jboss-fuse/bin/fabric-create.sh