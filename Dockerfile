FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update && apt-get install -y gnupg2

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

RUN "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list

RUN apt-get update -y

RUN apt-get dist-upgrade -y
RUN apt-get remove -y libcurl4
# lib32z1-dev \
RUN apt-get install apt-utils locales \
  tzdata bash git curl wget apt-utils \
  python-pip libxml2-dev libxslt-dev \
  python-lxml apt-utils locales \
  nodejs npm moreutils jq unzip \
  mono-complete pandoc libcurl4 \
  python3-pip python3.7 python3.7-dev \
  apt-transport-https ca-certificates curl software-properties-common curl -y \
  && apt-get install -y libcurl3 \
  && apt-get clean &&  apt autoclean -y && apt-get clean -y
# && apt autoremove -y

RUN apt-get install curl -y
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8


RUN dpkg-reconfigure -f noninteractive tzdata

#INSTALL DOCKER
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" >> /etc/apt/sources.list
RUN apt-get update && apt-cache policy docker-ce && apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

RUN npm install -g tap-xunit
RUN npm install -g bats

RUN wget https://github.com/GitTools/GitVersion/releases/download/v4.0.0-beta.14/GitVersion_4.0.0-beta0014.zip

RUN unzip GitVersion_4.0.0-beta0014.zip  -d GitVersion && cd GitVersion

RUN echo \#!/bin/bash >/usr/bin/gitversion
RUN echo mono /GitVersion/GitVersion.exe \"\$\@\" >>/usr/bin/gitversion

RUN chmod +x /usr/bin/gitversion

RUN rm /usr/bin/python3 && rm /usr/bin/python && ln -s /usr/bin/python3.7 /usr/bin/python && ln -s /usr/bin/python3.7 /usr/bin/python3
RUN pip3 install --upgrade pip && pip3 install --upgrade pip setuptools && pip3 install semantic_version

COPY requirements.txt /tmp

RUN pip3 install -r /tmp/requirements.txt && pip3 install junitparser

SHELL ["/bin/bash", "-c"]
ENV PATH="/root/.local/bin:/bin:${PATH}"

COPY splunk-appinspect /bin/splunk-appinspect
COPY check-appinspect-reports /bin/check-appinspect-reports
RUN apt-get install -y libcurl3

# To allow old builds to work...
RUN mkdir -p /usr/local/lib/python2.7/dist-packages/splunk_appinspect/checks/ && touch /usr/local/lib/python2.7/dist-packages/splunk_appinspect/checks/check_indexes_configuration_file.py  && \
touch /usr/local/lib/python2.7/dist-packages/splunk_appinspect/checks/check_saved_searches.py && \
touch /usr/local/lib/python2.7/dist-packages/splunk_appinspect/checks/check_cloud_simple_app.py

# Install Poetry
# Curl isnt installed due to conflict elsewhere which is as yet unresolved so using wget
RUN wget https://install.python-poetry.org -O /tmp/poetry-install && \
chmod +x /tmp/poetry-install && \
/tmp/poetry-install

# Install ACS CLI
RUN wget https://api.github.com/repos/splunk/acs-cli/releases/latest -O /tmp/acs-cli.json && \
wget $(cat /tmp/acs-cli.json | jq '.assets[] | select(.name | contains("linux_amd64")) | .browser_download_url' -r) -O /tmp/acs-cli.tar.gz && \
tar -xf /tmp/acs-cli.tar.gz --directory /bin
