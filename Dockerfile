####################################################################################################
## Builder
####################################################################################################
FROM rust:alpine AS builder

RUN apk add --no-cache \ 
    musl-dev \
    git

WORKDIR /libreddit

RUN git clone https://github.com/spikecodes/libreddit /libreddit

RUN cargo build --target x86_64-unknown-linux-musl --release

####################################################################################################
## Final image
####################################################################################################
FROM apline:edge

# Import ca-certificates from builder
COPY --from=builder /usr/share/ca-certificates /usr/share/ca-certificates
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

# Copy build
COPY --from=builder /libreddit/target/x86_64-unknown-linux-musl/release/libreddit /usr/local/bin/libreddit

# Add unprivileged user
RUN adduser --disabled-password --gecos "" libreddit
USER libreddit

EXPOSE 8080

HEALTHCHECK --interval=1m --timeout=3s CMD wget --spider --q http://localhost:8080/settings || exit 1

CMD ["libreddit"] 