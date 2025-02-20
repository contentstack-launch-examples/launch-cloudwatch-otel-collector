FROM otel/opentelemetry-collector-contrib:latest AS collector


FROM alpine:3.14 AS debug
RUN apk add --no-cache coreutils
COPY --from=collector /otelcol-contrib /otelcol-contrib

# Running locally
# ENV AWS_ACCESS_KEY_ID=""
# ENV AWS_SECRET_ACCESS_KEY=""
# ENV AWS_SESSION_TOKEN=""
# ENV AWS_REGION=us-east-1

COPY otelcol-config.yaml /etc/otelcol-config.yaml

EXPOSE 4317

CMD ["/otelcol-contrib",  "--config", "/etc/otelcol-config.yaml"]