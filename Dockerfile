# ------------------------------------------------------------
# Stage 1: Build markdown-tool binary
# ------------------------------------------------------------
FROM golang:1.25-bookworm AS markdown_tool_builder
ARG MARKDOWN_TOOL_REF=origin/main

WORKDIR /src
RUN git clone https://github.com/ErebusBat/markdown-tool.git . \
    && git checkout "${MARKDOWN_TOOL_REF}"
RUN CGO_ENABLED=0 go build -o /out/markdown-tool .

# ------------------------------------------------------------
# Stage 2: Build dlog runtime image
# ------------------------------------------------------------
FROM ruby:3.4.5
LABEL authors="aburns"

ENV DLOG_SLEEP=5
ENV DLOG_DELAY=30
ENV DLOG_NO_CHANGE=60
ENV DLOG_EXTRA_ARGS=--cache-config
ENV DLOG_CONFIG=/config/vault.rb

WORKDIR /app

# Install Ruby dependencies for dlog
COPY Gemfile* .
RUN bundle

# Copy markdown-tool binary from builder stage
COPY --from=markdown_tool_builder /out/markdown-tool /usr/local/bin/markdown-tool

# Verify markdown-tool is installed
RUN markdown-tool --help > /dev/null

# Copy dlog application source
COPY . .

CMD bin/dlog-fixup --watch --log-no-change $DLOG_NO_CHANGE --sleep $DLOG_SLEEP --delay $DLOG_DELAY $DLOG_EXTRA_ARGS
