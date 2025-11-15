# Vault Server Configuration
# Production-ready configuration for HashiCorp Vault

# Listener configuration
listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1  # Set to 0 in production with valid certificates
  # tls_cert_file = "/vault/tls/vault.crt"
  # tls_key_file  = "/vault/tls/vault.key"
}

# Storage backend - File storage (for demo)
# In production, use Consul, etcd, or cloud storage
storage "file" {
  path = "/vault/data"
}

# Storage backend - Consul (production example)
# storage "consul" {
#   address = "consul:8500"
#   path    = "vault/"
# }

# API address
api_addr = "http://0.0.0.0:8200"

# Cluster address
cluster_addr = "https://0.0.0.0:8201"

# UI
ui = true

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

# Enable response headers
# For security hardening
# response_headers {
#   "Strict-Transport-Security" = ["max-age=31536000; includeSubDomains"]
#   "X-Content-Type-Options"     = ["nosniff"]
#   "X-Frame-Options"            = ["DENY"]
# }

# Log level
log_level = "info"

# Disable mlock (for containers - enable in production)
disable_mlock = true

# Default lease duration
default_lease_ttl = "168h"  # 7 days
max_lease_ttl = "720h"      # 30 days
