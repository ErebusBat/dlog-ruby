FROM ruby:3.4.5
LABEL authors="aburns"

ENV DLOG_SLEEP=5
ENV DLOG_DELAY=30
ENV DLOG_NO_CHANGE=60
ENV DLOG_EXTRA_ARGS=--cache-config
ENV DLOG_CONFIG=/config/vault.rb

WORKDIR /app

# Setup Gems
COPY Gemfile* .
RUN bundle

# Now copy the rest of the app
COPY . .

CMD bin/dlog-fixup --watch --log-no-change $DLOG_NO_CHANGE --sleep $DLOG_SLEEP --delay $DLOG_DELAY $DLOG_EXTRA_ARGS
