$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'daemon_runner'
require 'dev/consul'
require 'securerandom'

## Minitest Teardown
at_exit { ::Dev::Consul.stop }
##

require 'minitest/autorun'

class ConsulIntegrationTest < Minitest::Test

  ## Setup
  ::Dev::Consul.run
  ::Dev::Consul.wait

  def setup
    @service = service_name
  end

  def service_name
    'myservice-' + SecureRandom.hex[0..10]
  end
end

