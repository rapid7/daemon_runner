require 'test_helper'
require_relative '../test_helper'
#
#curl -X PUT -d <body> http://localhost:8500/v1/kv/<prefix>/<session>?acquire=<session>
class SemaphoreTest < ConsulIntegrationTest

  def setup
    @sem = DaemonRunner::Semaphore.new(@service)
  end

  def test_can_write_contender_key
    @service = 'myservice1'
    @sem = DaemonRunner::Semaphore.new(@service)
    assert @sem.contender_key
  end
end
