# Launch-OpenTelemetry-LogTarget-Cloudwatch-Logs-exporter

This repo will host an intermediate OTEL collector service between log Target and forward the logs to the AWS Cloudwatch service.

Please note:
The request would fail in the case:
  1. The timestamp in the log message is older than the log_retention period in the otelcol-config.yaml
  2. The API Request would give 401 in case the bearertoken value doesn't match.



To debug any issue, You can add Debug exporter that will provide more details and You can also integrate health check for the OTEL Collector by using the [extensions here](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension). Learn more about [OpenTelemetry here](https://opentelemetry.io/).

To send a GRPC request you can refer to the [Opentelemetry Proto Specs](https://github.com/open-telemetry/opentelemetry-proto) and use either `Postman` or `gcurl`
