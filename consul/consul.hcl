# Consul configuration for observability stack
datacenter = "dc1"
data_dir = "/consul/data"
log_level = "INFO"
server = true
bootstrap_expect = 1

# Bind to all interfaces
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"

# Enable UI
ui_config {
  enabled = true
}

# Enable metrics collection
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

# ACL configuration (disabled for development)
acl = {
  enabled = false,
  default_policy = "allow"
}

# Connect (service mesh) configuration
connect {
  enabled = true
}

# Service definitions for observability stack
services {
  name = "grafana"
  port = 3000
  address = "grafana"
  tags = ["observability", "dashboards", "http-monitor", "tcp-monitor"]
  meta = {
    health_path = "/api/health"
  }
  check {
    http = "http://grafana:3000/api/health"
    interval = "30s"
    timeout = "5s"
  }
}

services {
  name = "prometheus"
  port = 9090
  address = "prometheus"
  tags = ["observability", "metrics", "http-monitor", "tcp-monitor"]
  meta = {
    health_path = "/-/healthy"
  }
  check {
    http = "http://prometheus:9090/-/healthy"
    interval = "30s"
    timeout = "5s"
  }
}

services {
  name = "loki"
  port = 3100
  address = "loki"
  tags = ["observability", "logs", "http-monitor", "tcp-monitor"]
  meta = {
    health_path = "/ready"
  }
  check {
    http = "http://loki:3100/ready"
    interval = "30s"
    timeout = "5s"
  }
}

services {
  name = "blackbox-exporter"
  port = 9115
  address = "blackbox-exporter"
  tags = ["observability", "monitoring", "http-monitor", "tcp-monitor"]
  meta = {
    health_path = "/metrics"
  }
  check {
    http = "http://blackbox-exporter:9115/metrics"
    interval = "30s"
    timeout = "5s"
  }
}

services {
  name = "nginx"
  port = 80
  address = "nginx"
  tags = ["web", "proxy", "tcp-monitor"]
  check {
    tcp = "nginx:80"
    interval = "30s"
    timeout = "5s"
  }
}

services {
  name = "metabase"
  port = 3000
  address = "metabase"
  tags = ["analytics", "bi", "tcp-monitor"]
  check {
    tcp = "metabase:3000"
    interval = "30s"
    timeout = "10s"
  }
}

services {
  name = "consul"
  port = 8500
  address = "consul"
  tags = ["service-discovery", "catalog", "http-monitor", "tcp-monitor"]
  meta = {
    health_path = "/v1/status/leader"
  }
  check {
    http = "http://consul:8500/v1/status/leader"
    interval = "30s"
    timeout = "5s"
  }
} 