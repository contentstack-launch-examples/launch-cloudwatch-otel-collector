
#!/bin/bash

docker build --platform linux/amd64 -t log-target-cw-logs-exporter .

docker run --platform linux/amd64 -p 4317:4317 -v $(pwd)/otelcol-config.yaml:/etc/otelcol-contrib/config.yaml log-target-cw-logs-exporter
