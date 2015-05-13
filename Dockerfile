FROM centos:centos6
MAINTAINER Guuuo <im@kuo.io>

#install tools
RUN yum -y update
RUN yum install -y wget unzip tar git python-setuptools
RUN easy_install supervisor
RUN mkdir -p /var/log/supervisor

#install jdk
ENV JAVA_VERSION 8u45
ENV BUILD_VERSION b14
RUN wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-$BUILD_VERSION/jdk-$JAVA_VERSION-linux-x64.rpm" -O /tmp/jdk-8-linux-x64.rpm
#COPY ./soft/jdk.rpm /tmp/jdk-8-linux-x64.rpm
RUN yum -y install /tmp/jdk-8-linux-x64.rpm
RUN rm -rf /tmp/jdk-8-linux-x64.rpm
RUN alternatives --install /usr/bin/java jar /usr/java/latest/bin/java 200000
RUN alternatives --install /usr/bin/javaws javaws /usr/java/latest/bin/javaws 200000
RUN alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000
ENV JAVA_HOME /usr/java/latest

#install tomcat
ENV TOMCAT_VERSION 7.0.61
RUN wget http://mirrors.cnnic.cn/apache/tomcat/tomcat-7/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.zip -O /tmp/tomcat.zip
#COPY ./soft/tomcat.zip /tmp/tomcat.zip
RUN unzip /tmp/tomcat.zip -d /tmp/
RUN rm -rf /tmp/tomcat.zip
RUN mkdir -p /data/instances
RUN mv /tmp/apache-tomcat-$TOMCAT_VERSION /data/instances/tomcat
RUN chmod 777 /data/instances/tomcat/bin/*.sh

#install maven
ENV MAVEN_VERSION 3.2.5
RUN wget http://www.eu.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz -O /tmp/maven.tar.gz
#COPY ./soft/maven.tar.gz /tmp/maven.tar.gz
RUN tar -xvf /tmp/maven.tar.gz -C /opt/
RUN rm -rf /tmp/maven.tar.gz
RUN ln -s /opt/apache-maven-$MAVEN_VERSION/bin/mvn /usr/bin/mvn
RUN mkdir -p /root/.m2
ENV MAVEN_HOME /opt/apache-maven-$MAVEN_VERSION

# get src
RUN mkdir -p /data/app
RUN git clone https://github.com/Guuuo/java-hello-world.git /data/app/hello-world

#package
RUN cd /data/app/hello-world; mvn package
RUN cp /data/app/hello-world/target/hello-world.war /data/instances/tomcat/webapps/hello-world.war

#run
ADD ./conf/supervisord.conf /etc/supervisord.conf
ADD ./conf/supervisord_tomcat.sh /data/instances/tomcat/bin/supervisord_tomcat.sh
RUN chmod 777 /data/instances/tomcat/bin/*.sh

EXPOSE 80 443 8080 8443 9001
CMD ["supervisord", "-n"]