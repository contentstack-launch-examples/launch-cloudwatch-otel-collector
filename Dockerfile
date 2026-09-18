FROM otel/opentelemetry-collector-contrib:latest AS collector

FROM public.ecr.aws/docker/library/alpine:latest AS debug
RUN apk add --no-cache coreutils curl
COPY --from=collector /otelcol-contrib /otelcol-contrib

# Copy our configuration
COPY otelcol-config.yaml /etc/otelcol-config.yaml

# Expose the gRPC port
EXPOSE 4317

# Start the collector with our configuration
CMD ["/otelcol-contrib", "--config", "/etc/otelcol-config.yaml"]