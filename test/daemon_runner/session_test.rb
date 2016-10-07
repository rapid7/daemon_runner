require_relative '../test_helper'
require 'dev/consul'

class SessionTest < ConsulIntegrationTest
  def test_can_get_session
    @service = 'myservice1'
    refute_nil @session
    assert_kind_of DaemonRunner::Session, @session
  end

  def test_can_aquire_lock
    @service = 'myservice2'
    assert DaemonRunner::Session.lock(@prefix)
  end

  def test_can_release_lock
    @service = 'myservice3'
    assert DaemonRunner::Session.lock(@prefix)
    assert DaemonRunner::Session.release(@prefix)
    assert @session.destroy!
    assert_raises(Faraday::ClientError) do
      DaemonRunner::Session.lock(@prefix)
    end
  end

end
