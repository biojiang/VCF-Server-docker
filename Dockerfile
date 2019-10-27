#
# MAINTAINER        Jiang Jianping <jianping.jiang@sjtu.edu.cn>
# DOCKER-VERSION    18.06.0-ce
#
# Dockerizing VCF-Server: Dockerfile for building VCF-Server
#
FROM mongo:4.2.0-bionic
MAINTAINER Jiang Jianping <jianping.jiang@sjtu.edu.cn>

#Install Perl cpanm
RUN apt-get -q update && apt-get install -qy --force-yes perl build-essential cpanminus apache2 libexpat1-dev libsasl2-dev wget git curl openjdk-11-jre zlib1g-dev libbz2-dev liblzma-dev supervisor

#install perl modules
RUN cpanm CGI JSON MongoDB XML::Simple IPC::SysV IPC::Msg Digest::MD5 Encode Time::HiRes List::Util

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

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64

RUN cp /usr/local/lib/libmongoc-1.0.so.0 /lib/x86_64-linux-gnu/ && cp /usr/local/lib/libbson-1.0.so.0 /lib/x86_64-linux-gnu/

#install nodejs
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -yq nodejs

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


#clone VCF-Server
RUN cd ~ && git clone https://github.com/biojiang/VCF-Server.git
RUN cd ~/VCF-Server && npm install

#remove dev tools
RUN apt-get purge -y --auto-remove wget git curl cpanminus 
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#import data

#configure apache2
RUN ln -s /etc/apache2/mods-available/cgid.conf /etc/apache2/mods-enabled/cgid.conf && ln -s /etc/apache2/mods-available/cgid.load /etc/apache2/mods-enabled/cgid.load && ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/cgi.load
RUN mkdir -p /usr/local/apache2/ && ln -s /usr/lib/cgi-bin/ /usr/local/apache2/
ADD VCF-Server.tar.gz /usr/local/apache2/cgi-bin/
ADD user.txt /etc/user.txt
ADD supervisord.conf /etc/supervisord.conf
RUN mkdir -p /data
VOLUME /data



#run application


EXPOSE 9000

CMD /usr/bin/supervisord -c /etc/supervisord.conf
