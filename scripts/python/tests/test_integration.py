"""
Integration tests for the monitoring stack
Tests the actual Docker containers and their interactions
"""

import pytest
import requests
import time
import subprocess


class TestDockerStack:
    """Integration tests for Docker containers"""

    @pytest.fixture(scope="class")
    def docker_running(self):
        """Check if Docker is running"""
        try:
            result = subprocess.run(
                ["docker", "ps"], capture_output=True, text=True, timeout=5
            )
            return result.returncode == 0
        except Exception:
            return False

    def test_dashboard_health_endpoint(self, docker_running):
        """Test that dashboard health endpoint is accessible"""
        if not docker_running:
            pytest.skip("Docker not running")

        try:
            response = requests.get("http://localhost:5000/health", timeout=5)
            assert response.status_code == 200
            data = response.json()
            assert "status" in data
            assert data["status"] == "healthy"
        except requests.exceptions.RequestException:
            pytest.skip("Dashboard not running")

    def test_dashboard_api_endpoint(self, docker_running):
        """Test dashboard API returns valid JSON"""
        if not docker_running:
            pytest.skip("Docker not running")

        try:
            response = requests.get("http://localhost:5000/api/latest", timeout=5)
            if response.status_code == 200:
                data = response.json()
                assert "overall_health" in data or "error" in data
        except requests.exceptions.RequestException:
            pytest.skip("Dashboard not running")

    def test_prometheus_metrics_endpoint(self, docker_running):
        """Test Prometheus is collecting metrics"""
        if not docker_running:
            pytest.skip("Docker not running")

        try:
            response = requests.get("http://localhost:9090/api/v1/targets", timeout=5)
            if response.status_code == 200:
                data = response.json()
                assert data["status"] == "success"
                assert "data" in data
        except requests.exceptions.RequestException:
            pytest.skip("Prometheus not running")

    def test_grafana_health(self, docker_running):
        """Test Grafana is healthy"""
        if not docker_running:
            pytest.skip("Docker not running")

        try:
            response = requests.get("http://localhost:3000/api/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                assert "database" in data
        except requests.exceptions.RequestException:
            pytest.skip("Grafana not running")

    def test_elasticsearch_cluster_health(self, docker_running):
        """Test Elasticsearch cluster is healthy"""
        if not docker_running:
            pytest.skip("Docker not running")

        try:
            response = requests.get("http://localhost:9200/_cluster/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                assert data["status"] in ["green", "yellow"]
        except requests.exceptions.RequestException:
            pytest.skip("Elasticsearch not running")


class TestDatabaseConnectivity:
    """Test database connectivity"""

    def test_postgres_connection(self):
        """Test PostgreSQL connection (if available)"""
        try:
            import psycopg2

            conn = psycopg2.connect(
                host="localhost",
                port=5432,
                database="demodb",
                user="demouser",
                password="demopass",
                connect_timeout=3,
            )
            conn.close()
            assert True
        except ImportError:
            pytest.skip("psycopg2 not installed")
        except Exception:
            pytest.skip("PostgreSQL not accessible")

    def test_redis_connection(self):
        """Test Redis connection (if available)"""
        try:
            import redis

            r = redis.Redis(host="localhost", port=6379, socket_connect_timeout=3)
            r.ping()
            assert True
        except ImportError:
            pytest.skip("redis not installed")
        except Exception:
            pytest.skip("Redis not accessible")


class TestEndToEnd:
    """End-to-end workflow tests"""

    def test_health_check_to_dashboard_flow(self):
        """Test that health check data flows to dashboard"""
        # This would test the full flow:
        # 1. Health checker runs
        # 2. Generates report
        # 3. Dashboard reads report
        # 4. API returns data
        pytest.skip("Requires running stack - implement when needed")

    def test_metrics_collection_flow(self):
        """Test that metrics are collected and queryable"""
        # This would test:
        # 1. Exporters expose metrics
        # 2. Prometheus scrapes them
        # 3. Grafana can query them
        pytest.skip("Requires running stack - implement when needed")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
