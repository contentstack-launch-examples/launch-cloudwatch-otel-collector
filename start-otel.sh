
#!/bin/bash

docker build --platform linux/amd64 -t log-target-cw-logs-exporter .

docker run --platform linux/amd64 -v $(pwd)/otelcol-config.yaml:/etc/otelcol-contrib/config.yaml log-target-cw-logs-exporter
