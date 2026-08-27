FROM otel/opentelemetry-collector-contrib:latest AS collector

FROM public.ecr.aws/docker/library/alpine:latest AS debug
# snyk-fix(27-Aug-2026): pinned libcrypto3/libssl3 to 3.5.8-r0 (SNYK-ALPINE324-OPENSSL-19257375 + 9 more)
# — alpine:latest currently resolves to 3.24.x, which still ships 3.5.7-r0.
# These are the two openssl libraries the base image actually contains; the openssl CLI
# is not installed and is not needed, so it is deliberately not added here.
# snyk-fix TODO: remove this pin once the base image itself ships >= 3.5.8-r0; re-scan will confirm.
RUN apk add --no-cache coreutils curl libcrypto3=3.5.8-r0 libssl3=3.5.8-r0
COPY --from=collector /otelcol-contrib /otelcol-contrib

# Copy our configuration
COPY otelcol-config.yaml /etc/otelcol-config.yaml

# Expose the gRPC port
EXPOSE 4317

# Start the collector with our configuration
CMD ["/otelcol-contrib", "--config", "/etc/otelcol-config.yaml"]