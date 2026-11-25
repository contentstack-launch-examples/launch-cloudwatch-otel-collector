FROM otel/opentelemetry-collector-contrib:latest AS collector

FROM public.ecr.aws/docker/library/alpine:latest AS debug
# snyk-fix(25-Nov-2026): pinned zlib to >=1.4-r0 for SNYK-ALPINE324-ZLIB-22265522 — alpine:3.24.4 shipped 1.3.2-r1.
# snyk-fix TODO: remove this pin only once the base image ships zlib >= 1.4-r0 and every build pulls a fresh base (e.g. --pull in build-and-push.sh); re-scan alone won't show it.
# snyk-fix(25-Nov-2026): pinned libcrypto3 and libssl3 to >=3.5.9-r1 for SNYK-ALPINE324-OPENSSL-22602641, SNYK-ALPINE324-OPENSSL-22602642, SNYK-ALPINE324-OPENSSL-22602643, SNYK-ALPINE324-OPENSSL-22602645, SNYK-ALPINE324-OPENSSL-22602647.
# snyk-fix TODO: remove this pin only once the base image ships openssl >= 3.5.9-r1 and every build pulls a fresh base (e.g. --pull in build-and-push.sh); re-scan alone won't show it.
# snyk-fix(25-Nov-2026): pinned musl and musl-utils to >=1.2.6-r3 for SNYK-ALPINE324-MUSL-21430842 — kept because build-and-push.sh reuses a cached alpine:latest without --pull.
# snyk-fix TODO: remove this pin once every build of this image pulls a fresh base (e.g. --pull in build-and-push.sh); re-scan alone won't show it.
RUN apk add --no-cache coreutils curl 'zlib>=1.4-r0' 'libcrypto3>=3.5.9-r1' 'libssl3>=3.5.9-r1' 'musl>=1.2.6-r3' 'musl-utils>=1.2.6-r3'
COPY --from=collector /otelcol-contrib /otelcol-contrib

# Copy our configuration
COPY otelcol-config.yaml /etc/otelcol-config.yaml

# Expose the gRPC port
EXPOSE 4317

# Start the collector with our configuration
CMD ["/otelcol-contrib", "--config", "/etc/otelcol-config.yaml"]