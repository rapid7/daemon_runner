require_relative '../test_helper'

class SemaphoreTest < ConsulIntegrationTest
  def setup
    super
    @sem = DaemonRunner::Semaphore.new(name: @service)
    @session = @sem.session
  end

  def test_can_get_prefix
    assert_equal "service/#{@service}/lock/", @sem.prefix
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
    @sem.contender_key
    @sem.semaphore_state
    @sem.set_limit(3)
    @sem.try_lock
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
    @sem = DaemonRunner::Semaphore.start(@service)
    lock = DaemonRunner::Semaphore.lock
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

  def test_can_get_two_uniq_lock_sessions
    @service1 = service_name
    @service2 = service_name

    @sem1 = DaemonRunner::Semaphore.start(@service1)
    @sem2 = DaemonRunner::Semaphore.start(@service2)
    refute_equal @sem1.session.id, @sem2.session.id
  end
end
