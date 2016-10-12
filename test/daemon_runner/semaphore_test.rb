require 'test_helper'
require_relative '../test_helper'
#
#curl -X PUT -d <body> http://localhost:8500/v1/kv/<prefix>/<session>?acquire=<session>

class TestDaemonRunnerSemaphore < DaemonRunner::Semaphore

  def members
    ['foo', session.id]
  end

  def lock_modify_index
    21
  end

  def lock_content
    {
      'Limit' => 3,
      'Holders' => {
        '84263834-5f54-a595-2069-0ffb474e8d34' => true,
        session.id.to_s => true
      }
    }
  end
end

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
    refute_empty @sem.semaphore_state
    refute_nil @sem.state
    assert_respond_to @sem.state, :each
    assert_respond_to @sem.members, :each

    assert_nil @sem.lock_modify_index
    assert_nil @sem.lock_content
  end

  def test_can_get_empty_lock
    @sem = DaemonRunner::Semaphore.new('myservice4')
    @sem.semaphore_state
    refute @sem.lock_exists?
  end

  def test_lock_exists_can_be_falsey
    @sem = DaemonRunner::Semaphore.new('myservice5')
    refute @sem.lock_exists?
  end

  def test_lock_exists_can_be_truthy
    @sem = TestDaemonRunnerSemaphore.new('myservice6')
    assert @sem.lock_exists?
  end

  def test_can_compare_lockfile_members_with_members
    @sem = TestDaemonRunnerSemaphore.new('myservice7')
    assert_equal [@sem.session.id], @sem.active_members
    assert_respond_to @sem.active_members, :each
  end
end
