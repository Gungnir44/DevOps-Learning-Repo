# Dockerfile Security Policies with OPA
# Enforce Docker best practices and security standards

package dockerfile.analysis

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Deny Dockerfiles using latest tag
deny[msg] {
    input[i].Cmd == "from"
    val := input[i].Value
    contains(val[i], ":latest")
    msg := sprintf("Line %d: Do not use 'latest' tag for base images", [i])
}

# Deny running as root
deny[msg] {
    not has_user_directive
    msg := "Dockerfile must specify USER directive (do not run as root)"
}

has_user_directive {
    input[_].Cmd == "user"
}

# Deny images from untrusted registries
deny[msg] {
    input[i].Cmd == "from"
    val := input[i].Value[0]
    trusted_registries := ["docker.io/", "gcr.io/", "quay.io/", "ghcr.io/", "mcr.microsoft.com/"]
    not starts_with_any_registry(val, trusted_registries)
    not is_official_image(val)
    msg := sprintf("Line %d: Use images only from trusted registries", [i])
}

starts_with_any_registry(image, registries) {
    some registry in registries
    startswith(image, registry)
}

is_official_image(image) {
    not contains(image, "/")
}

# Warn on missing HEALTHCHECK
warn[msg] {
    not has_healthcheck
    msg := "Dockerfile should include HEALTHCHECK instruction"
}

has_healthcheck {
    input[_].Cmd == "healthcheck"
}

# Deny using ADD instead of COPY
deny[msg] {
    input[i].Cmd == "add"
    val := input[i].Value
    not is_url(val[0])
    not is_archive(val[0])
    msg := sprintf("Line %d: Use COPY instead of ADD for copying files", [i])
}

is_url(path) {
    startswith(path, "http://")
}

is_url(path) {
    startswith(path, "https://")
}

is_archive(path) {
    endswith(path, ".tar")
}

is_archive(path) {
    endswith(path, ".tar.gz")
}

is_archive(path) {
    endswith(path, ".zip")
}

# Deny exposing dangerous ports
deny[msg] {
    input[i].Cmd == "expose"
    dangerous_ports := ["22", "23", "3389", "5900"]
    port := input[i].Value[_]
    port in dangerous_ports
    msg := sprintf("Line %d: Do not expose dangerous port %v", [i, port])
}

# Require specific base image versions
warn[msg] {
    input[i].Cmd == "from"
    val := input[i].Value[0]
    not contains(val, "@sha256:")
    not contains(val, ":")
    msg := sprintf("Line %d: Specify explicit version tag for base image", [i])
}

# Deny storing secrets in ENV
deny[msg] {
    input[i].Cmd == "env"
    val := lower(input[i].Value[0])
    secret_keywords := ["password", "secret", "key", "token", "credential"]
    some keyword in secret_keywords
    contains(val, keyword)
    msg := sprintf("Line %d: Do not store secrets in ENV variables", [i])
}

# Require labels for metadata
warn[msg] {
    not has_maintainer_label
    msg := "Dockerfile should include maintainer label"
}

has_maintainer_label {
    input[i].Cmd == "label"
    contains(input[i].Value[0], "maintainer")
}

# Deny apt-get without --no-install-recommends
deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, "apt-get install")
    not contains(val, "--no-install-recommends")
    msg := sprintf("Line %d: Use --no-install-recommends with apt-get install", [i])
}

# Deny missing cleanup after package installation
deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, "apt-get install")
    not contains(val, "rm -rf /var/lib/apt/lists/*")
    msg := sprintf("Line %d: Clean up apt cache after installation", [i])
}

# Deny curl pipe to bash
deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, "curl")
    contains(val, "| bash")
    msg := sprintf("Line %d: Avoid piping curl to bash (security risk)", [i])
}

# Warn on WORKDIR not using absolute path
warn[msg] {
    input[i].Cmd == "workdir"
    val := input[i].Value[0]
    not startswith(val, "/")
    msg := sprintf("Line %d: WORKDIR should use absolute path", [i])
}

# Deny COPY with overly permissive permissions
deny[msg] {
    input[i].Cmd == "copy"
    val := concat(" ", input[i].Value)
    contains(val, "--chmod=777")
    msg := sprintf("Line %d: Do not use chmod 777", [i])
}

# Require multi-stage builds for compiled languages
warn[msg] {
    has_build_tools
    not is_multistage
    msg := "Consider using multi-stage builds to reduce image size"
}

has_build_tools {
    input[i].Cmd == "run"
    val := lower(concat(" ", input[i].Value))
    build_tools := ["gcc", "make", "maven", "gradle", "npm install", "go build"]
    some tool in build_tools
    contains(val, tool)
}

is_multistage {
    count([x | input[x].Cmd == "from"]) > 1
}

# Deny running update/upgrade without install
deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(val, "apt-get update")
    not contains(val, "apt-get install")
    msg := sprintf("Line %d: apt-get update should be combined with install", [i])
}

# Best practice: Pin package versions
warn[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    package_managers := ["apt-get install", "yum install", "apk add", "pip install"]
    some pm in package_managers
    contains(val, pm)
    not contains(val, "=")
    msg := sprintf("Line %d: Consider pinning package versions", [i])
}

# Compliance: Require security scanning labels
warn[msg] {
    not has_security_scan_label
    msg := "Add label to indicate security scanning status"
}

has_security_scan_label {
    input[i].Cmd == "label"
    contains(input[i].Value[0], "security.scan")
}
