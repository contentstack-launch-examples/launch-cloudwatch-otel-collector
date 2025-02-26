# Launch OpenTelemetry Collector example  

- Hosts an OTLP Receiver with Authorization Bearer Token value configurable with `otel-contrib.yaml`
- Export Log Request to Cloudwatch

This repository hosts an intermediate OpenTelemetry (OTEL) Collector service that acts as a bridge between Log Targets and AWS CloudWatch Logs. The service receives logs from Log Targets and forwards them to AWS CloudWatch Logs for storage and analysis. 

## Important Notes

### Service fails to export Logs to Cloudwatch
An Export Log request may fail in the following cases:
1. The timestamp in the log message is older than the `log_retention` period defined in `otelcol-config.yaml`.
2. The API request will return a `401 Unauthorized` error if the provided bearer token does not match the expected value in the `otel-contrib.yaml`.

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

1. Update the AWS Credentials in the Dockerfile
2. Start the OTEL collector service. with following command:
```sh
sh start-otel.sh
```

This will launch the OTEL Collector using the provided configuration.

## Next Steps?

- Host this service using AWS ECS
- Secure the endpoint of the service using Application Load balancer with correct credentials
- You'd be required to enable the TLS traffic with a certificate and route the traffic internally to 443 to 4317 that of the running container
- Verify the endpoint is receiving logs using the GRPC Message in the example folder
- Follow the step to [Create the Log Target ](https://www.contentstack.com/docs/developers/launch/log-targets#create-a-log-target) add the endpoint of your service. And don't miss to configure the the Bearer Token(currently referred as Secret Token) 
