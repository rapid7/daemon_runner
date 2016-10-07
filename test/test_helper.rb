$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'daemon_runner'
require 'dev/consul'

## Minitest Teardown
at_exit { ::Dev::Consul.stop }
##

require 'minitest/autorun'

class ConsulIntegrationTest < Minitest::Test

  ## Setup
  ::Dev::Consul.run
  ::Dev::Consul.wait

  ## Teardown
  def teardown
    @session = nil
    sleep 1
  end
end

