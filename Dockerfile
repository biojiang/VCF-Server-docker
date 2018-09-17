#
# MAINTAINER        Jiang Jianping <jianping.jiang@sjtu.edu.cn>
# DOCKER-VERSION    18.06.0-ce
#
# Dockerizing VCF-Server: Dockerfile for building VCF-Server
#
FROM httpd:2.4
MAINTAINER Jiang Jianping <jianping.jiang@sjtu.edu.cn>

#Install Perl cpanm
RUN [ "apt-get", "-q", "update" ]
RUN [ "apt-get", "-qy", "--force-yes", "upgrade" ]
RUN [ "apt-get", "-qy", "--force-yes", "dist-upgrade" ]
RUN [ "apt-get", "install", "-qy", "--force-yes", \
      "perl", \
      "build-essential", \
      "cpanminus" ]
RUN [ "apt-get", "clean" ]
RUN [ "rm", "-rf", "/var/lib/apt/lists/*", "/tmp/*", "/var/tmp/*" ]

#install perl modules
RUN cpanm CGI JSON MongoDB XML::Simple IPC::SysV IPC::Msg Digest::MD5 Encode Time::HiRes List::Util

#install mongoc
RUN apt-get install -qy --force-yes libsasl2-dev wget git && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd ~ \
    && wget https://cmake.org/files/v3.12/cmake-3.12.1.tar.gz \
    && tar xzf cmake-3.12.1.tar.gz \
    && cd cmake-3.12.1 \
    && ./bootstrap \
    && make \
    && make install \
    && rm ~/cmake-3.12.1.tar.gz

RUN cd ~ \
    && wget https://github.com/mongodb/mongo-c-driver/releases/download/1.12.0/mongo-c-driver-1.12.0.tar.gz \
    && tar xzf mongo-c-driver-1.12.0.tar.gz \
    && cd mongo-c-driver-1.12.0 \
    && mkdir cmake-build \
    && cd cmake-build \
    && cmake -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF .. \
    && make \
    && make install \
    && cd ~ \
    && rm mongo-c-driver-1.12.0.tar.gz \
    && rm -rf mongo-c-driver-1.12.0

RUN cd ~/cmake-3.12.1 \
    && make uninstall \
    && rm -rf ~/cmake-3.12.1
###############
#   Mongo DB
###############

# Procedure from the official Mongo Doc.
# https://docs.mongodb.com/manual/tutorial/install- 
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
RUN echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
RUN apt-get update
RUN apt-get install -y mongodb-org 

#Install java
RUN \
  apt-get update && \
  apt-get install -y openjdk-7-jre && \
  rm -rf /var/lib/apt/lists/*
# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

RUN cp /usr/local/lib/libmongoc-1.0.so.0 /lib/x86_64-linux-gnu/ && cp /usr/local/lib/libbson-1.0.so.0 /lib/x86_64-linux-gnu/

#install nodejs & PM2
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -yq nodejs build-essential
RUN npm install pm2 -g

#install zlib bz2 lzma
RUN \
  apt-get update && \
  apt-get install -y zlib1g-dev libbz2-dev liblzma-dev && \
  rm -rf /var/lib/apt/lists/*


#install htslib
RUN cd ~ \
    && wget https://github.com/samtools/htslib/releases/download/1.9/htslib-1.9.tar.bz2 \
    && tar -xjf htslib-1.9.tar.bz2 \
    && cd htslib-1.9 \
    && ./configure \
    && make \
    && make install \
    && cd ~ \
    && rm htslib-1.9.tar.bz2 \
    && rm -rf htslib-1.9

#install supervisor
RUN apt-get update && apt-get install -qy --force-yes supervisor && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


#clone VCF-Server
RUN cd ~ && git clone https://github.com/biojiang/VCF-Server.git
RUN cd ~/VCF-Server && npm install

#remove dev tools
RUN apt-get purge -y --auto-remove wget git 
#import data

ADD VCF-Server.tar.gz /usr/local/apache2/cgi-bin/
COPY httpd.conf /usr/local/apache2/conf/
ADD user.txt /etc/user.txt
ADD supervisord.conf /etc/supervisord.conf
#RUN mkdir -p /data/users/admin/ && mkdir -p /data/users/public/example && mkdir -p /data/logs/
RUN mkdir /data
VOLUME /data

#mongodb data path
#RUN mkdir -p /data/db /data/configdb && chown -R mongodb:mongodb /data/db /data/configdb
#VOLUME /data/db /data/configdb


#run application

#ENTRYPOINT ["mongod"]
#ENTRYPOINT ["perl","/usr/local/apache2/cgi-bin/VCF-Server/tools/TaskManager.pl",">","TaskManage.log","2>&1"]
#ENTRYPOINT ["pm2-docker","start","~/VCF-Server/app.js","--name","VCF-Server"]

EXPOSE 9000

CMD /usr/bin/supervisord -c /etc/supervisord.conf
