require 'test_helper'
require_relative '../test_helper'
#
#curl -X PUT -d <body> http://localhost:8500/v1/kv/<prefix>/<session>?acquire=<session>
class SemaphoreTest < ConsulIntegrationTest

  def test_can_get_prefix
    @service = 'myservice1'
    @sem = DaemonRunner::Semaphore.new(@service)
    assert_equal 'service/myservice1/lock/', @sem.prefix
  end

  def test_can_set_prefix
    @service = 'myservice1'
    assert_equal 'foo/', DaemonRunner::Semaphore.new(@service, 'foo').prefix
    assert_equal 'bar/', DaemonRunner::Semaphore.new(@service, 'bar/').prefix
  end

  def test_can_write_contender_key
    @sem = DaemonRunner::Semaphore.new('myservice1')
    assert @sem.contender_key
  end

  def test_can_get_empty_semapore_state
    @sem = DaemonRunner::Semaphore.new('myservice2')
    assert_empty @sem.semaphore_state
  end

  def test_can_get_semapore_state
    @sem = DaemonRunner::Semaphore.new('myservice3')
    @sem.contender_key
    state = @sem.semaphore_state
    refute_nil state 
    assert_respond_to state, :each
  end
end
