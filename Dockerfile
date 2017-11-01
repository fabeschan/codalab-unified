FROM ubuntu:16.04
MAINTAINER Fabian Chan <fabianc@stanford.edu>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y build-essential git
RUN apt-get install -y libfuse-dev libjpeg-dev
RUN apt-get install -y libmysqlclient-dev mysql-client
RUN apt-get install -y python-dev python-pip
RUN apt-get install -y python-software-properties python-virtualenv software-properties-common
RUN apt-get install -y zip curl

ARG CACHEBUST=1

WORKDIR /opt
RUN git clone https://github.com/codalab/codalab-worksheets.git
# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash -
RUN apt-get install -y nodejs
RUN echo '{ "allow_root": true }' > /root/.bowerrc
ENV CODALAB_HOME=/home/codalab
RUN cd /opt/codalab-worksheets && ./setup.sh

WORKDIR /opt
RUN git clone -b fabianc-test https://github.com/codalab/codalab-cli.git

RUN cd /opt/codalab-cli && ./setup.sh server
ENV PATH="/opt/codalab-cli/codalab/bin:${PATH}"
ENV CODALAB_HOME=/home/codalab

RUN apt-get install -y supervisor
RUN mkdir -p /var/log/supervisor

ENV CODALAB_USERNAME=codalab
ENV CODALAB_PASSWORD=1234

RUN cl config server/class SQLiteModel
RUN cl config server/rest_host 0.0.0.0
RUN cl config server/engine_url sqlite:////home/codalab/bundle.db
WORKDIR /opt/codalab-cli
RUN venv/bin/python scripts/create-root-user.py 1234

RUN mkdir /opt/worker
COPY passwordfile /opt/worker/passwordfile
RUN chmod 600 /opt/worker/passwordfile

RUN mkdir /tmp/scratch

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
