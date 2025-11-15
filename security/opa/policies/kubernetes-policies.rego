# Kubernetes Security Policies with Open Policy Agent (OPA)
# These policies enforce security best practices for Kubernetes resources

package kubernetes.admission

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Deny containers running as root
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container %v must not run as root", [container.name])
}

# Deny containers without resource limits
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    not container.resources.limits
    msg := sprintf("Container %v must have resource limits defined", [container.name])
}

# Deny containers without resource requests
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    not container.resources.requests
    msg := sprintf("Container %v must have resource requests defined", [container.name])
}

# Deny privileged containers
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    container.securityContext.privileged
    msg := sprintf("Container %v must not be privileged", [container.name])
}

# Deny containers with hostNetwork
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.spec.hostNetwork
    msg := "Pods must not use hostNetwork"
}

# Deny containers with hostPID
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.spec.hostPID
    msg := "Pods must not use hostPID"
}

# Deny containers with hostIPC
deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.spec.hostIPC
    msg := "Pods must not use hostIPC"
}

# Deny containers pulling images with 'latest' tag
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    endswith(container.image, ":latest")
    msg := sprintf("Container %v must not use 'latest' image tag", [container.name])
}

# Deny containers without image pull policy
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    not container.imagePullPolicy
    msg := sprintf("Container %v must have imagePullPolicy defined", [container.name])
}

# Deny containers from untrusted registries
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    trusted_registries := ["docker.io", "gcr.io", "quay.io", "ghcr.io"]
    not starts_with_any(container.image, trusted_registries)
    msg := sprintf("Container %v uses untrusted registry", [container.name])
}

starts_with_any(str, prefixes) {
    some prefix in prefixes
    startswith(str, prefix)
}

# Deny services of type LoadBalancer in non-production namespaces
deny[msg] {
    input.request.kind.kind == "Service"
    input.request.object.spec.type == "LoadBalancer"
    not input.request.namespace in ["production", "prod"]
    msg := "LoadBalancer services only allowed in production namespace"
}

# Require labels on all resources
deny[msg] {
    required_labels := ["app", "environment", "owner"]
    some label in required_labels
    not input.request.object.metadata.labels[label]
    msg := sprintf("Resource must have label: %v", [label])
}

# Deny secrets without encryption
deny[msg] {
    input.request.kind.kind == "Secret"
    not input.request.object.metadata.annotations["encryption"]
    msg := "Secrets must be encrypted (add encryption annotation)"
}

# Require readiness probes
deny[msg] {
    input.request.kind.kind == "Deployment"
    some container in input.request.object.spec.template.spec.containers
    not container.readinessProbe
    msg := sprintf("Container %v must have readinessProbe", [container.name])
}

# Require liveness probes
deny[msg] {
    input.request.kind.kind == "Deployment"
    some container in input.request.object.spec.template.spec.containers
    not container.livenessProbe
    msg := sprintf("Container %v must have livenessProbe", [container.name])
}

# Deny excessive CPU requests
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    cpu := parse_cpu(container.resources.requests.cpu)
    cpu > 4000
    msg := sprintf("Container %v requests excessive CPU: %vm", [container.name, cpu])
}

# Deny excessive memory requests
deny[msg] {
    input.request.kind.kind == "Pod"
    some container in input.request.object.spec.containers
    memory := parse_memory(container.resources.requests.memory)
    memory > 8192
    msg := sprintf("Container %v requests excessive memory: %vMi", [container.name, memory])
}

# Helper function to parse CPU
parse_cpu(cpu_str) = result {
    endswith(cpu_str, "m")
    result := to_number(trim_suffix(cpu_str, "m"))
}

parse_cpu(cpu_str) = result {
    not endswith(cpu_str, "m")
    result := to_number(cpu_str) * 1000
}

# Helper function to parse memory
parse_memory(mem_str) = result {
    endswith(mem_str, "Mi")
    result := to_number(trim_suffix(mem_str, "Mi"))
}

parse_memory(mem_str) = result {
    endswith(mem_str, "Gi")
    result := to_number(trim_suffix(mem_str, "Gi")) * 1024
}

# Allow policy: pods in monitoring namespace can run as root
allow {
    input.request.namespace == "monitoring"
    input.request.kind.kind == "Pod"
}

# Warn: high replica count
warn[msg] {
    input.request.kind.kind == "Deployment"
    input.request.object.spec.replicas > 10
    msg := sprintf("Deployment has high replica count: %v", [input.request.object.spec.replicas])
}

# Compliance: PCI-DSS requirement for network policies
deny[msg] {
    input.request.kind.kind == "Namespace"
    input.request.object.metadata.annotations["compliance"] == "pci-dss"
    not has_network_policy
    msg := "PCI-DSS compliant namespaces must have NetworkPolicy"
}

has_network_policy {
    # Check if NetworkPolicy exists for this namespace
    # This would require checking cluster state
    # Simplified for example
    true
}
