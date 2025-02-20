# Launch OpenTelemetry Collector example  

- Receives the logs from Log Target and forward them to the AWS Cloudwatch service

This repository hosts an intermediate OpenTelemetry (OTEL) Collector service that acts as a bridge between Log Targets and AWS CloudWatch Logs. The service receives logs from Log Targets and forwards them to AWS CloudWatch Logs for storage and analysis.

## Important Notes

### Request Failures
A request may fail in the following cases:
1. The timestamp in the log message is older than the `log_retention` period defined in `otelcol-config.yaml`.
2. The API request will return a `401 Unauthorized` error if the provided bearer token does not match the expected value.

## Debugging Issues
To diagnose potential issues:
- Add a **Debug Exporter** to obtain detailed logging information.
- Integrate a **Health Check Extension** for monitoring the OTEL Collector’s health. You can explore available extensions [here](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension).
- Learn more about OpenTelemetry by visiting the official documentation [here](https://opentelemetry.io/).

## Sending gRPC Requests
To send a gRPC request to the OTEL Collector, refer to the [OpenTelemetry Protocol (OTLP) Specifications](https://github.com/open-telemetry/opentelemetry-proto). You can use tools like:
- **Postman**
- **gcurl** (a gRPC-enabled version of curl)

## Running the OTEL Collector Locally
To start the OTEL Collector locally, run the following command:

```sh
sh start-otel.sh
```

This will launch the OTEL Collector using the provided configuration.

