require_relative '../test_helper'

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

class TestDaemonRunnerSemaphore2 < TestDaemonRunnerSemaphore
  def active_members
    ['foo', session.id]
  end
end

class SemaphoreTest < ConsulIntegrationTest
  def setup
    super
    @sem = DaemonRunner::Semaphore.new(name: @service)
    @session = @sem.session
  end

  def test_can_get_prefix
    assert_equal 'service/myservice1/lock/', @sem.prefix
  end

  def test_can_set_prefix_without_ending_slash
    assert_equal 'foo/', DaemonRunner::Semaphore.new(name: @service, prefix: 'foo').prefix
  end

  def test_can_set_prefix_with_ending_slash
    assert_equal 'bar/', DaemonRunner::Semaphore.new(name: @service, prefix: 'bar/').prefix
  end

  def test_can_write_contender_key
    assert @sem.contender_key
  end

  def test_can_get_empty_semapore_state
    assert_empty @sem.semaphore_state
  end

  def test_can_get_semapore_state
    @sem.contender_key
    refute_empty @sem.semaphore_state
    refute_nil @sem.state
    assert_respond_to @sem.state, :each
    assert_respond_to @sem.members, :each

    assert_nil @sem.lock_modify_index
    assert_nil @sem.lock_content
  end

  def test_can_write_lockfile
    @service = service_name
    @sem = DaemonRunner::Semaphore.new(name: @service)
    @sem.limit = 3
    @sem.contender_key
    @sem.semaphore_state
    @sem.write_lock
    lockfile = {
      'Limit' => 3,
      'Holders' => {
        @sem.session.id.to_s => true
      }
    }

    @sem.semaphore_state
    assert_equal lockfile, @sem.lock_content
  end

  def test_can_get_semapore_lock
    DaemonRunner::Semaphore.lock
    lockfile = {
      'Limit' => 3,
      'Holders' => {
        @sem.session.id.to_s => true
      }
    }

    @sem.semaphore_state
    assert_equal lockfile, @sem.lock_content
  end

  def test_can_get_semapore_lock_with_options
    skip
    @service = service_name
    @sem = DaemonRunner::Semaphore.start(@service, prefix: "service/#{@service}/lock")
    DaemonRunner::Semaphore.lock
    lockfile = {
      'Limit' => 3,
      'Holders' => {
        @sem.session.id.to_s => true
      }
    }

    @sem.semaphore_state
    assert_equal lockfile, @sem.lock_content
  end

  def test_can_get_semapore_lock_with_no_update
    # Client 1
    @service1 = service_name
    @sem1 = DaemonRunner::Semaphore.start(@service1)
    DaemonRunner::Semaphore.lock(1)

    # Client 2
    @service2 = service_name
    @sem2 = DaemonRunner::Semaphore.start(@service2)
    DaemonRunner::Semaphore.lock(1)

    lockfile = {
      'Limit' => 1,
      'Holders' => {
        @sem1.session.id.to_s => true
      }
    }

    @sem1.semaphore_state
    assert_equal lockfile, @sem1.lock_content

    @sem2.semaphore_state
    assert_equal lockfile, @sem2.lock_content
  end
end
