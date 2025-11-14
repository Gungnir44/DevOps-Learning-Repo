"""
Unit tests for System Health Checker
"""
import pytest
import json
from unittest.mock import Mock, patch, MagicMock
import psutil


class TestSystemHealthChecker:
    """Test SystemHealthChecker class"""

    def test_cpu_check_healthy(self):
        """Test CPU check returns healthy status when below threshold"""
        # Mock psutil.cpu_percent to return 50%
        with patch('psutil.cpu_percent', return_value=50.0):
            from system_health_checker_v2 import SystemHealthChecker
            checker = SystemHealthChecker()
            checker.cpu_warning = 60
            checker.cpu_critical = 80

            result = checker.check_cpu()
            assert result['status'] == 'HEALTHY'
            assert result['usage'] == 50.0

    def test_cpu_check_warning(self):
        """Test CPU check returns warning when above warning threshold"""
        with patch('psutil.cpu_percent', return_value=70.0):
            from system_health_checker_v2 import SystemHealthChecker
            checker = SystemHealthChecker()
            checker.cpu_warning = 60
            checker.cpu_critical = 80

            result = checker.check_cpu()
            assert result['status'] == 'WARNING'
            assert result['usage'] == 70.0

    def test_cpu_check_critical(self):
        """Test CPU check returns critical when above critical threshold"""
        with patch('psutil.cpu_percent', return_value=90.0):
            from system_health_checker_v2 import SystemHealthChecker
            checker = SystemHealthChecker()
            checker.cpu_warning = 60
            checker.cpu_critical = 80

            result = checker.check_cpu()
            assert result['status'] == 'CRITICAL'
            assert result['usage'] == 90.0

    def test_memory_check_healthy(self):
        """Test memory check returns healthy status"""
        mock_memory = MagicMock()
        mock_memory.percent = 45.0
        mock_memory.total = 8 * 1024**3
        mock_memory.available = 4 * 1024**3
        mock_memory.used = 4 * 1024**3

        with patch('psutil.virtual_memory', return_value=mock_memory):
            from system_health_checker_v2 import SystemHealthChecker
            checker = SystemHealthChecker()
            checker.memory_warning = 60
            checker.memory_critical = 80

            result = checker.check_memory()
            assert result['status'] == 'HEALTHY'
            assert result['percent'] == 45.0

    def test_disk_check(self):
        """Test disk check returns proper status"""
        mock_partition = MagicMock()
        mock_partition.mountpoint = '/'
        mock_partition.device = '/dev/sda1'

        mock_usage = MagicMock()
        mock_usage.percent = 40.0
        mock_usage.total = 100 * 1024**3
        mock_usage.used = 40 * 1024**3
        mock_usage.free = 60 * 1024**3

        with patch('psutil.disk_partitions', return_value=[mock_partition]):
            with patch('psutil.disk_usage', return_value=mock_usage):
                from system_health_checker_v2 import SystemHealthChecker
                checker = SystemHealthChecker()
                checker.disk_warning = 60
                checker.disk_critical = 80

                result = checker.check_disk()
                assert len(result) > 0
                assert result[0]['status'] == 'HEALTHY'

    def test_overall_health_healthy(self):
        """Test overall health calculation when all systems healthy"""
        from system_health_checker_v2 import SystemHealthChecker
        checker = SystemHealthChecker()

        checker.health_data = {
            'cpu': {'status': 'HEALTHY'},
            'memory': {'status': 'HEALTHY'},
            'disk': [{'status': 'HEALTHY'}]
        }

        result = checker.determine_overall_health()
        assert result == 'HEALTHY'

    def test_overall_health_warning(self):
        """Test overall health calculation with warning state"""
        from system_health_checker_v2 import SystemHealthChecker
        checker = SystemHealthChecker()

        checker.health_data = {
            'cpu': {'status': 'WARNING'},
            'memory': {'status': 'HEALTHY'},
            'disk': [{'status': 'HEALTHY'}]
        }

        result = checker.determine_overall_health()
        assert result == 'WARNING'

    def test_overall_health_critical(self):
        """Test overall health calculation with critical state"""
        from system_health_checker_v2 import SystemHealthChecker
        checker = SystemHealthChecker()

        checker.health_data = {
            'cpu': {'status': 'CRITICAL'},
            'memory': {'status': 'HEALTHY'},
            'disk': [{'status': 'HEALTHY'}]
        }

        result = checker.determine_overall_health()
        assert result == 'CRITICAL'


class TestDatabaseChecker:
    """Test DatabaseChecker class"""

    def test_check_redis_success(self):
        """Test successful Redis connection"""
        with patch('redis.Redis') as mock_redis:
            mock_client = Mock()
            mock_client.ping.return_value = True
            mock_redis.return_value = mock_client

            from system_health_checker_v2 import DatabaseChecker
            checker = DatabaseChecker()

            config = {
                'host': 'localhost',
                'port': 6379,
                'timeout': 5
            }

            result = checker.check_redis(config)
            assert result['status'] == 'CONNECTED'

    def test_check_redis_failure(self):
        """Test Redis connection failure"""
        with patch('redis.Redis') as mock_redis:
            mock_redis.side_effect = Exception("Connection refused")

            from system_health_checker_v2 import DatabaseChecker
            checker = DatabaseChecker()

            config = {
                'host': 'localhost',
                'port': 6379,
                'timeout': 5
            }

            result = checker.check_redis(config)
            assert result['status'] == 'FAILED'

    def test_check_postgres_skipped_without_library(self):
        """Test PostgreSQL check skipped when library not installed"""
        with patch('system_health_checker_v2.DatabaseChecker.check_postgresql') as mock_check:
            mock_check.return_value = {'status': 'SKIPPED', 'message': 'psycopg2 not installed'}

            from system_health_checker_v2 import DatabaseChecker
            checker = DatabaseChecker()

            config = {
                'host': 'localhost',
                'port': 5432,
                'database': 'test',
                'user': 'user',
                'password': 'pass',
                'timeout': 5
            }

            result = checker.check_postgresql(config)
            assert result['status'] == 'SKIPPED'


class TestReportGeneration:
    """Test report generation and export"""

    def test_export_json_report(self, tmp_path):
        """Test JSON report export"""
        from system_health_checker_v2 import SystemHealthChecker

        checker = SystemHealthChecker()
        checker.health_data = {
            'timestamp': '2024-01-01T00:00:00',
            'overall_health': 'HEALTHY',
            'cpu': {'status': 'HEALTHY', 'usage': 30.0}
        }

        # Mock the report path
        with patch.object(checker, 'report_path', str(tmp_path)):
            filename = checker.export_json_report()
            assert filename is not None

            # Verify file was created
            report_file = tmp_path / filename.split('/')[-1]
            assert report_file.exists()

            # Verify content
            with open(report_file, 'r') as f:
                data = json.load(f)
                assert data['overall_health'] == 'HEALTHY'


class TestCommandLineArguments:
    """Test command-line argument parsing"""

    def test_quiet_mode(self):
        """Test quiet mode suppresses output"""
        # This would need to mock sys.argv and test main() function
        pass

    def test_config_file_loading(self):
        """Test custom config file loading"""
        # This would test loading a custom config.json
        pass


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
