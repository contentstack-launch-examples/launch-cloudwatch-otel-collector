FROM otel/opentelemetry-collector-contrib:latest AS collector

FROM public.ecr.aws/docker/library/alpine:latest AS debug
# snyk-fix(12-Oct-2026): pinned zlib to >=1.3.2-r1 for SNYK-ALPINE324-ZLIB-20541555 — alpine:3.24.2 shipped 1.3.2-r0.
# snyk-fix TODO: remove this pin once the base image itself ships zlib >= 1.3.2-r1; re-scan will confirm.
RUN apk add --no-cache coreutils curl 'zlib>=1.3.2-r1'
COPY --from=collector /otelcol-contrib /otelcol-contrib

# Copy our configuration
COPY otelcol-config.yaml /etc/otelcol-config.yaml

# Expose the gRPC port
EXPOSE 4317

# Start the collector with our configuration
CMD ["/otelcol-contrib", "--config", "/etc/otelcol-config.yaml"]