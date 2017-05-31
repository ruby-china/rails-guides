FROM ruby:2.4.1

RUN mkdir /app
WORKDIR /app

RUN apt-get update && apt-get -y install imagemagick

RUN mkdir /tmp/kindlegen && cd /tmp/kindlegen && \
    wget http://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz && \
    tar xfz kindlegen_linux_2.6_i386_v2_9.tar.gz && \
    mv kindlegen /usr/local/bin/

RUN gem install bundler

COPY Gemfile /app
COPY Gemfile.lock /app
RUN bundle install

ENV GUIDES_LANGUAGE=zh-CN
ENV RAILS_VERSION=v5.1.1
