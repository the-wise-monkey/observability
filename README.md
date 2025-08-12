# Observability Stack

A comprehensive, production-ready observability and monitoring platform built with Docker Compose. This stack provides complete visibility into your infrastructure through metrics collection, log aggregation, uptime monitoring, error tracking, and business intelligence analytics.

## 🏗️ Architecture Overview

```
                              ┌─────────────────┐
                              │      Nginx      │
                              │   (Port 80)     │
                              │ Reverse Proxy   │
                              └─────────┬───────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
         ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
         │    Grafana      │  │   Prometheus    │  │     Consul      │
         │  (Port 3000)    │  │  (Port 9090)    │  │  (Port 8500)    │
         │   Dashboards    │  │    Metrics      │  │Service Discovery│
         └─────────┬───────┘  └─────────┬───────┘  └─────────┬───────┘
                   │                    │                    │
                   │          ┌─────────┴───────┐            │
                   │          │                 │            │
         ┌─────────────────┐  │       ┌─────────────────┐    │
         │      Loki       │  │       │ Blackbox Export │    │
         │  (Port 3100)    │◄─┤       │  (Port 9115)    │◄───┤
         │      Logs       │  │       │ Uptime Monitor  │    │
         └─────────┬───────┘  │       └─────────────────┘    │
                   ▲          │                              │
         ┌─────────┴───────┐  │       ┌─────────────────┐    │ 
         │    Promtail     │  │       │    Metabase     │    │
         │  (Port 9080)    │  │       │  (Port 3030)    │────┘
         │ Log Collection  │  │       │   Analytics     │
                   └─────────────────┘  │       └─────────────────┘
                              │
                     ┌─────────┴───────┐
                    │                 │
              External Systems    Host Logs
              (via Consul SD)     (/var/log)
```

**Data Flow:**
- **Nginx** → Routes traffic to all web services
- **Prometheus** → Scrapes metrics from all services + Consul service discovery
- **Grafana** → Queries Prometheus (metrics) + Loki (logs) for visualization
- **Loki** ← Receives logs from Promtail
- **Promtail** → Collects host logs and forwards to Loki
- **Consul** → Provides service discovery for Prometheus + Blackbox monitoring
- **Blackbox** → Monitors endpoints discovered via Consul

## 🔧 Components

### Core Monitoring
- **[Grafana](https://grafana.com/)** - Visualization, dashboards, and alerting
- **[Loki](https://grafana.com/oss/loki/)** - Log aggregation and querying
- **[Prometheus](https://prometheus.io/)** - Time-series metrics collection and storage
- **[Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)** - Log collection agent

### Infrastructure
- **[Metabase](https://www.metabase.com/)** - Business intelligence and analytics
- **[Nginx](https://nginx.org/)** - Reverse proxy for unified web access


### Service Discovery & Health
- **[Blackbox Exporter](https://github.com/prometheus/blackbox_exporter)** - HTTP/TCP/ICMP endpoint monitoring
- **[Consul](https://www.consul.io/)** - Service discovery, health checking, and configuration

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Linux system with systemd (for production deployment)
- Bash shell

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd observability
   ```

2. **Run the setup script**
   ```bash
   ./manage
   ```
   
   The script will guide you through:
   - Environment configuration
   - Service setup
   - Systemd integration (optional)

3. **Access the services**
   
   Once running, access your services at:
   - **Blackbox**: `http://your-server/blackbox`
   - **Consul**: `http://your-server/consul`
   - **Grafana**: `http://your-server/grafana` (admin/admin)
   - **Metabase**: `http://your-server/metabase`
   - **Prometheus**: `http://your-server/prometheus`

## 📁 Project Structure

```
observability/
├── 📂 blackbox/                 # Blackbox Exporter configuration
│   └── blackbox.yml            # HTTP/TCP/ICMP probes config
├── 📂 consul/                   # Consul service discovery
│   └── consul.hcl              # Consul agent configuration
├── 📂 loki/                     # Log aggregation
│   ├── loki-config.yaml        # Loki server configuration
│   └── 📂 data/                # Persistent log storage
├── 📂 prometheus/               # Metrics collection
│   └── prometheus.yml          # Scrape configs & service discovery
├── 📂 promtail/                 # Log collection
│   └── promtail-config.yaml    # Log scraping configuration
├── 🐳 docker-compose.yml        # Container orchestration
├── 🌐 nginx.conf               # Reverse proxy configuration
├── 🔧 manage                   # Setup and management script
└── 📋 README.md               # This file
```

## ⚙️ Configuration

### Environment Variables
Configuration is managed through `.env` file (created during setup):

```bash
# Metabase Configuration
MB_DB_CONNECTION_URI="your-database-connection"
MB_SITE_URL="http://your-server/metabase"
```

### Service Discovery
Services are automatically registered in Consul with health checks and monitoring tags. The stack supports:

- **Automatic service discovery** via Consul
- **Dynamic target discovery** for Prometheus
- **Health monitoring** with configurable checks
- **Tag-based monitoring** (http-monitor, tcp-monitor, prometheus)

### Monitoring Capabilities

#### Health Monitoring
- **Alerting**: Integration with Prometheus alerting
- **Custom endpoints**: Configurable health check paths
- **Multi-protocol**: HTTP, TCP, ICMP probes
- **Service health**: Consul-integrated health checks

#### Log Aggregation
- **Centralized logging**: All container logs via Promtail
- **Log correlation**: Integrated with metrics via Grafana
- **Push API**: Direct log ingestion endpoint
- **Structured logs**: JSON and key-value parsing

#### Metrics Collection
- **Custom endpoints**: HTTP/TCP probes via Blackbox Exporter
- **Flexible scraping**: Tag-based service selection
- **Self-monitoring**: All stack components expose metrics
- **Service discovery**: Auto-discovery of services via Consul

#### Error Tracking
- **Real-time error monitoring**: Capture and track application errors
- **Performance monitoring**: Track application performance metrics
- **Release tracking**: Monitor error rates across releases
- **Issue management**: Organize and prioritize error reports
- **Integration**: Connect with development workflows

## 🛠️ Management

### Manual Operations
```bash
# Start the stack
docker compose up -d

# Stop the stack
docker compose down

# View logs
docker compose logs -f [service-name]

# Restart a service
docker compose restart [service-name]
```

### Using the Management Script
```bash
# Run interactive management
./manage

# The script provides:
# - Initial setup and configuration
# - Environment variable management
# - Systemd service integration
# - Service status monitoring
```

## 🔒 Security Considerations

### Default Credentials
- **Consul**: No authentication (development mode)
- **Grafana**: admin/admin (change on first login)

### Production Hardening
For production deployment:

1. **Configure Grafana authentication**
2. **Enable Consul ACLs**
3. **Implement network segmentation**
4. **Regular security updates**
5. **Set up TLS certificates**

## 📊 Monitoring Dashboards

### Pre-configured Monitoring
- **Application metrics**: Service health, response times
- **Business metrics**: Custom KPIs via Metabase
- **Infrastructure metrics**: CPU, memory, disk, network
- **Log analysis**: Error rates, log volumes

### Custom Dashboards
Create custom Grafana dashboards for:
- Application-specific metrics
- Business KPIs
- Custom alerting rules
- SLA monitoring

## 🤝 Contributing

1. Follow the coding standards defined in `.cursorrules`
2. Test changes with the full stack
3. Update documentation for new features
4. Ensure backward compatibility

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

**Services not starting:**
```bash
# Check logs
docker compose logs -f

# Verify configuration
docker compose config
```

**Consul service discovery not working:**
```bash
# Check Consul UI
curl http://localhost:8500/v1/catalog/services

# Verify service registration
docker compose exec consul consul members
```

**Metrics not appearing:**
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Verify scrape configs
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

### Support

For issues and questions:
1. Check the troubleshooting section
2. Consult component documentation
3. Open an issue in the repository
4. Review service logs

---

*Built with ❤️ for comprehensive observability*
