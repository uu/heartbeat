
require "test/unit"
require "stringio"
require "logger"

require File.expand_path("../../lib/failover_ip", __FILE__)

class FailoverIpTest < Test::Unit::TestCase
  def test_ping
    assert FailoverIp.new(nil, "", "127.0.0.1", []).ping
  end

  def test_up?
    assert FailoverIp.new(nil, "", "127.0.0.1", []).up?
  end

  def test_down?
    assert FailoverIp.new(nil, "", "111.111.111.111", []).down?
  end

  def test_next_ip
    failover_ip = FailoverIp.new(nil, "", "", ["127.0.0.1", "127.0.0.2", "111.111.111.111", "127.0.0.3"])

    assert_equal "127.0.0.2", failover_ip.next_ip("127.0.0.1")
    assert_equal "127.0.0.3", failover_ip.next_ip("127.0.0.2")
    assert_equal "127.0.0.1", failover_ip.next_ip("127.0.0.3")

    failover_ip = FailoverIp.new(nil, "", "", ["111.111.111.111", "222.222.222"])

    assert_nil failover_ip.next_ip("111.111.111.111")
    assert_nil failover_ip.next_ip("222.222.222.222")
  end

  def test_initialize
    logger = Logger.new(StringIO.new)

    failover_ip = FailoverIp.new(logger, "base_url", "failover_ip", ["ip1", "ip2"])

    assert_equal logger, failover_ip.logger
    assert_equal "base_url", failover_ip.base_url
    assert_equal "failover_ip", failover_ip.failover_ip
    assert_equal ["ip1", "ip2"], failover_ip.ips
  end

  def test_current_ip
    # Can't be tested.
  end

  def test_switch_ips
    # Can't be tested.
  end

  def test_logger
    # Already tested.
  end

  def test_base_url
    # Already tested.
  end

  def test_failover_ip
    # Already tested.
  end

  def test_ips
    # Already tested.
  end
end
