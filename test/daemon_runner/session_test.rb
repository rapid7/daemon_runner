require_relative '../test_helper'
require 'dev/consul'

class SessionTest < ConsulIntegrationTest
  def setup
    super
    @session = ::DaemonRunner::Session.start(@service)
    @prefix = "service/#{@service}/lock"
  end

  def test_can_get_session
    refute_nil @session
    assert_kind_of DaemonRunner::Session, @session
  end

  def test_can_aquire_lock
    assert DaemonRunner::Session.lock(@prefix)
  end

  def test_can_release_lock
    assert DaemonRunner::Session.lock(@prefix)
    assert DaemonRunner::Session.release(@prefix)
    assert @session.destroy!
    assert_raises(Faraday::ClientError) do
      DaemonRunner::Session.lock(@prefix)
    end
  end

  def test_can_get_two_uniq_sessions
    @service1 = service_name
    @service2 = service_name
    @session1 = ::DaemonRunner::Session.start(@service1)
    @session2 = ::DaemonRunner::Session.start(@service2)
    refute_equal @session1.id, @session2.id
  end
end
