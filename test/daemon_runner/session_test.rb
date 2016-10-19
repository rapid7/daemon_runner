require_relative '../test_helper'
require 'dev/consul'

class SessionTest < ConsulIntegrationTest
  def setup
    super
    @session = ::DaemonRunner::Session.start(@service)
    @sem = DaemonRunner::Semaphore.new(name: @service)
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
end
