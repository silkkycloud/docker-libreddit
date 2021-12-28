ARG LIBREDDIT_VERSION=0.21.1

####################################################################################################
## Builder
####################################################################################################
FROM rust:1.57-alpine3.14 AS Builder

ARG LIBREDDIT_VERSION

RUN apk add --no-cache \
    ca-certificates \
    musl-dev \
    tar

WORKDIR /libreddit

ADD https://github.com/spikecodes/libreddit/archive/v${LIBREDDIT_VERSION}.tar.gz /tmp/libreddit-${LIBREDDIT_VERSION}.tar.gz
RUN tar xvfz /tmp/libreddit-${LIBREDDIT_VERSION}.tar.gz -C /tmp \
    && cp -r /tmp/libreddit-${LIBREDDIT_VERSION}/. /libreddit

RUN cargo build --target x86_64-unknown-linux-musl --release

####################################################################################################
## Final image
####################################################################################################
FROM alpine:3.15

ARG LIBREDDIT_VERSION

RUN apk add --no-cache \
    ca-certificates \
    tini

WORKDIR /libreddit

COPY --from=builder /libreddit/target/x86_64-unknown-linux-musl/release/libreddit /libreddit/libreddit

# Add an unprivileged user and set directory permissions
RUN adduser --disabled-password --gecos "" --no-create-home libreddit \
    && chown -R libreddit:libreddit /libreddit

ENTRYPOINT ["/sbin/tini", "--"]

USER libreddit

CMD ["./libreddit"]

EXPOSE 8080

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=30s \
    --interval=1m \
    --timeout=5s \
    CMD wget --spider --q http://localhost:8080/settings || exit 1

# Image metadata
LABEL org.opencontainers.image.version=${LIBREDDIT_VERSION}
LABEL org.opencontainers.image.title=Libreddit
LABEL org.opencontainers.image.description="Libreddit is a private front-end like Invidious but for Reddit. Browse the coldest takes of r/unpopularopinion without being tracked."
LABEL org.opencontainers.image.url=https://libreddit.silkky.cloud
LABEL org.opencontainers.image.vendor="Silkky.Cloud"
LABEL org.opencontainers.image.licenses=Unlicense
LABEL org.opencontainers.image.source="https://github.com/silkkycloud/docker-libreddit"