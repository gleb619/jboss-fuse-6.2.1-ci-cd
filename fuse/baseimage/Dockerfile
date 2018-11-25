# Use latest jboss/base-jdk:8 image as the base
FROM jboss/base-jdk:8

MAINTAINER Boris Velichko <boris86496@gmail.com>

USER root

COPY install.sh /opt/jboss/
RUN /opt/jboss/install.sh

USER jboss