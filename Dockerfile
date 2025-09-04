FROM ruby:3.4.5
LABEL authors="aburns"

ENV DLOG_SLEEP=5
ENV DLOG_DELAY=30
ENV DLOG_CONFIG=/config/vault.rb

WORKDIR /app
COPY . .
RUN bundle

CMD bin/dlog-fixup --watch --sleep $DLOG_SLEEP --delay $DLOG_DELAY
