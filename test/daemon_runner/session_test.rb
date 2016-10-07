require_relative '../test_helper'
require 'dev/consul'

class SessionTest < ConsulIntegrationTest
  def test_can_get_session
    @session = ::DaemonRunner::Session.start('myservice1')
    @prefix = "service/#{@service}/lock"
    refute_nil @session
    assert_kind_of DaemonRunner::Session, @session
  end

  def test_can_aquire_lock
    @session = ::DaemonRunner::Session.start('myservice2')
    @prefix = "service/#{@service}/lock"
    assert DaemonRunner::Session.lock(@prefix)
  end

  def test_can_release_lock
    @session = ::DaemonRunner::Session.start('myservice3')
    @prefix = "service/#{@service}/lock"
    assert DaemonRunner::Session.lock(@prefix)
    assert DaemonRunner::Session.release(@prefix)
    assert @session.destroy!
    assert_raises(Faraday::ClientError) do
      DaemonRunner::Session.lock(@prefix)
    end
  end

end
