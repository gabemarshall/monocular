FROM ruby:2.5
MAINTAINER Gabe Marshall
RUN apt-get update -yqq && apt-get install -y build-essential libpq-dev git-core curl openssl libssl-dev libcurl4-openssl-dev zlib1g zlib1g-dev
RUN mkdir /monocular
WORKDIR /monocular
COPY . /monocular
RUN bundle install
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
WORKDIR /monocular/tools/monocle-brute
RUN npm install
RUN apt-get install -y nmap
WORKDIR /monocular
