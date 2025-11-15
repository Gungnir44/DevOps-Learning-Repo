#!/usr/bin/env python3
"""
Vault Integration Demo Application
Demonstrates how to use HashiCorp Vault for secrets management
"""

import os
import time
import hvac
import sys
from datetime import datetime


def print_section(title):
    """Print formatted section header"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")


def connect_to_vault():
    """Connect to Vault server"""
    vault_addr = os.getenv('VAULT_ADDR', 'http://vault:8200')
    vault_token = os.getenv('VAULT_TOKEN', 'devroot')

    print_section("Connecting to Vault")
    print(f"Vault Address: {vault_addr}")

    client = hvac.Client(url=vault_addr, token=vault_token)

    if client.is_authenticated():
        print("✓ Successfully authenticated with Vault")
        return client
    else:
        print("✗ Failed to authenticate with Vault")
        sys.exit(1)


def demo_static_secrets(client):
    """Demonstrate static secrets (KV v2)"""
    print_section("Demo 1: Static Secrets (Key-Value Store)")

    # Enable KV v2 secrets engine
    try:
        client.sys.enable_secrets_engine(
            backend_type='kv',
            path='secret',
            options={'version': '2'}
        )
        print("✓ Enabled KV v2 secrets engine at 'secret/'")
    except Exception as e:
        print(f"KV engine already enabled: {e}")

    # Write a secret
    secret_data = {
        'username': 'admin',
        'password': 'SuperSecretPassword123!',
        'api_key': 'sk-1234567890abcdef',
        'db_connection': 'postgresql://user:pass@localhost:5432/db'
    }

    client.secrets.kv.v2.create_or_update_secret(
        path='app/config',
        secret=secret_data
    )
    print("✓ Wrote secret to 'secret/app/config'")
    print(f"  Data: {secret_data}")

    # Read the secret
    secret = client.secrets.kv.v2.read_secret_version(
        path='app/config'
    )
    print("\n✓ Read secret from Vault:")
    for key, value in secret['data']['data'].items():
        print(f"  {key}: {'*' * len(str(value))}")

    # List secrets
    secrets_list = client.secrets.kv.v2.list_secrets(path='app')
    print(f"\n✓ Secrets under 'secret/app/': {secrets_list['data']['keys']}")


def demo_dynamic_secrets(client):
    """Demonstrate dynamic database secrets"""
    print_section("Demo 2: Dynamic Database Secrets")

    # Enable database secrets engine
    try:
        client.sys.enable_secrets_engine(
            backend_type='database',
            path='database'
        )
        print("✓ Enabled database secrets engine")
    except Exception as e:
        print(f"Database engine already enabled: {e}")

    # Configure PostgreSQL connection
    try:
        client.secrets.database.configure(
            name='postgresql',
            plugin_name='postgresql-database-plugin',
            allowed_roles=['readonly'],
            connection_url='postgresql://{{username}}:{{password}}@postgres:5432/appdb?sslmode=disable',
            username='vault',
            password='vaultpass'
        )
        print("✓ Configured PostgreSQL connection")
    except Exception as e:
        print(f"PostgreSQL connection already configured: {e}")

    # Create a role for readonly access
    try:
        client.secrets.database.create_role(
            name='readonly',
            db_name='postgresql',
            creation_statements=[
                "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
                "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
            ],
            default_ttl='1h',
            max_ttl='24h'
        )
        print("✓ Created 'readonly' role")
    except Exception as e:
        print(f"Role already exists: {e}")

    # Generate dynamic credentials
    try:
        creds = client.secrets.database.generate_credentials(name='readonly')
        print("\n✓ Generated dynamic database credentials:")
        print(f"  Username: {creds['data']['username']}")
        print(f"  Password: {creds['data']['password']}")
        print(f"  Lease Duration: {creds['lease_duration']} seconds")
        print(f"  Lease ID: {creds['lease_id']}")
        print("\n  These credentials will automatically expire!")
    except Exception as e:
        print(f"Error generating credentials: {e}")


def demo_encryption_as_service(client):
    """Demonstrate encryption as a service (Transit)"""
    print_section("Demo 3: Encryption as a Service (Transit)")

    # Enable transit secrets engine
    try:
        client.sys.enable_secrets_engine(
            backend_type='transit',
            path='transit'
        )
        print("✓ Enabled transit secrets engine")
    except Exception as e:
        print(f"Transit engine already enabled: {e}")

    # Create encryption key
    try:
        client.secrets.transit.create_key(name='customer-data')
        print("✓ Created encryption key 'customer-data'")
    except Exception as e:
        print(f"Key already exists: {e}")

    # Encrypt data
    plaintext = "Sensitive customer information: SSN 123-45-6789"
    import base64
    plaintext_b64 = base64.b64encode(plaintext.encode()).decode()

    encrypted = client.secrets.transit.encrypt_data(
        name='customer-data',
        plaintext=plaintext_b64
    )
    ciphertext = encrypted['data']['ciphertext']
    print(f"\n✓ Encrypted data:")
    print(f"  Plaintext: {plaintext}")
    print(f"  Ciphertext: {ciphertext}")

    # Decrypt data
    decrypted = client.secrets.transit.decrypt_data(
        name='customer-data',
        ciphertext=ciphertext
    )
    decrypted_plaintext = base64.b64decode(decrypted['data']['plaintext']).decode()
    print(f"\n✓ Decrypted data:")
    print(f"  Result: {decrypted_plaintext}")


def demo_policies(client):
    """Demonstrate Vault policies"""
    print_section("Demo 4: Vault Policies (Access Control)")

    # Create a policy
    policy = """
    # Read-only access to secret/app/*
    path "secret/data/app/*" {
        capabilities = ["read", "list"]
    }

    # Full access to secret/dev/*
    path "secret/data/dev/*" {
        capabilities = ["create", "read", "update", "delete", "list"]
    }

    # Encrypt/decrypt with transit
    path "transit/encrypt/customer-data" {
        capabilities = ["update"]
    }
    path "transit/decrypt/customer-data" {
        capabilities = ["update"]
    }
    """

    client.sys.create_or_update_policy(
        name='app-policy',
        policy=policy
    )
    print("✓ Created 'app-policy' with limited permissions")
    print(policy)


def demo_audit_logging(client):
    """Demonstrate audit logging"""
    print_section("Demo 5: Audit Logging")

    # Enable file audit device
    try:
        client.sys.enable_audit_device(
            device_type='file',
            options={'file_path': '/vault/logs/audit.log'}
        )
        print("✓ Enabled audit logging to /vault/logs/audit.log")
        print("  All Vault operations are now logged for security auditing")
    except Exception as e:
        print(f"Audit device already enabled: {e}")


def demo_kubernetes_auth(client):
    """Demonstrate Kubernetes authentication method"""
    print_section("Demo 6: Kubernetes Authentication")

    print("Kubernetes auth method allows pods to authenticate with Vault")
    print("using their service account tokens.")
    print("\nConfiguration steps:")
    print("  1. Enable Kubernetes auth method")
    print("  2. Configure Kubernetes API address")
    print("  3. Create role binding service accounts to policies")
    print("  4. Pods use service account token to get Vault token")
    print("\nExample command:")
    print("  vault write auth/kubernetes/role/myapp \\")
    print("    bound_service_account_names=myapp \\")
    print("    bound_service_account_namespaces=default \\")
    print("    policies=app-policy \\")
    print("    ttl=24h")


def main():
    """Main demo function"""
    print("\n" + "="*60)
    print("  HashiCorp Vault Integration Demo")
    print("  Demonstrating Secrets Management Best Practices")
    print("="*60)
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # Connect to Vault
    client = connect_to_vault()

    # Run demonstrations
    try:
        demo_static_secrets(client)
        time.sleep(2)

        demo_dynamic_secrets(client)
        time.sleep(2)

        demo_encryption_as_service(client)
        time.sleep(2)

        demo_policies(client)
        time.sleep(2)

        demo_audit_logging(client)
        time.sleep(2)

        demo_kubernetes_auth(client)

    except Exception as e:
        print(f"\n✗ Error during demo: {e}")
        import traceback
        traceback.print_exc()

    print_section("Demo Complete")
    print("Vault provides:")
    print("  ✓ Centralized secrets management")
    print("  ✓ Dynamic secrets with automatic rotation")
    print("  ✓ Encryption as a service")
    print("  ✓ Fine-grained access control")
    print("  ✓ Complete audit trail")
    print("  ✓ Multiple authentication methods")
    print("\nFor production use:")
    print("  - Enable TLS")
    print("  - Use proper storage backend (Consul, etc.)")
    print("  - Initialize and unseal properly")
    print("  - Implement auto-unseal")
    print("  - Regular backups")
    print("  - HA configuration")

    # Keep container running
    print("\nKeeping demo app running... (Ctrl+C to stop)")
    try:
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        print("\nShutting down...")


if __name__ == '__main__':
    main()
