FROM otel/opentelemetry-collector-contrib:latest AS collector

FROM public.ecr.aws/docker/library/alpine:latest AS debug
# snyk-fix(25-Nov-2026): pinned zlib to >=1.4-r0 for SNYK-ALPINE324-ZLIB-22265522 — alpine:3.24.4 shipped 1.3.2-r1.
# snyk-fix TODO: remove this pin once the base image itself ships zlib >= 1.4-r0; re-scan will confirm.
# snyk-fix(25-Nov-2026): pinned libcrypto3 and libssl3 to >=3.5.9-r1 for SNYK-ALPINE324-OPENSSL-22602641/-42/-43/-45/-47 — alpine:3.24.4 shipped 3.5.9-r0.
# snyk-fix TODO: remove this pin once the base image itself ships openssl >= 3.5.9-r1; re-scan will confirm.
RUN apk add --no-cache coreutils curl 'zlib>=1.4-r0' 'libcrypto3>=3.5.9-r1' 'libssl3>=3.5.9-r1'
COPY --from=collector /otelcol-contrib /otelcol-contrib

# Copy our configuration
COPY otelcol-config.yaml /etc/otelcol-config.yaml

# Expose the gRPC port
EXPOSE 4317

# Start the collector with our configuration
CMD ["/otelcol-contrib", "--config", "/etc/otelcol-config.yaml"]