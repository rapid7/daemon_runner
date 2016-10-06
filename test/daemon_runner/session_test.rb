require_relative '../test_helper'
require 'dev/consul'

class SessionTest < Minitest::Test

  ## Setup
  Dev::Consul.run
  sleep 2
  Dev::Consul.wait

  def setup
    @session = ::DaemonRunner::Session.start(@service)
    @prefix = "service/#{@service}/lock"
  end
  ###

  ## Teardown
  def teardown
    @session = nil
    sleep 1
  end
  Minitest.after_run { Dev::Consul.stop }
  ###

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
