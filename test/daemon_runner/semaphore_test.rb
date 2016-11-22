require_relative '../test_helper'

class MockSemaphore
  attr_reader :callstack

  def initialize(lock_check: nil)
    @lock_check = lock_check
    @callstack = []
  end

  def locked?
    @callstack << :locked?
    if @lock_check.nil?
      false
    else
      @lock_check.call
    end
  end

  def lock
    @callstack << :lock
  end

  def try_lock
    @callstack << :try_lock
  end

  def renew
    @callstack << :renew
    nil
  end

  def release
    @callstack << :release
  end
end

class SemaphoreTest < ConsulIntegrationTest
  def setup
    super
    @sem = DaemonRunner::Semaphore.new(name: @service)
    @session = @sem.session
  end

  def teardown
    super
    ObjectSpace.each_object(DaemonRunner::Semaphore) do |semaphore|
      semaphore.release
    end
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
    @sem = DaemonRunner::Semaphore.new(name: @service, limit: 3)
    @sem.contender_key
    @sem.semaphore_state
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
    @sem = DaemonRunner::Semaphore.new(name: @service)
    lock = @sem.lock
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
    @service = service_name
    @sem = DaemonRunner::Semaphore.new(name: @service, prefix: "service/#{@service}/lock")
    @sem.lock
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
    @sem1 = DaemonRunner::Semaphore.new(name: @service, limit: 1)
    @sem1.lock

    # Client 2
    @sem2 = DaemonRunner::Semaphore.new(name: @service, limit: 1)
    @sem2.lock

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

  def test_semaphore_lock_with_default_limit
    @sem = DaemonRunner::Semaphore.lock(@service)
    assert_equal 3, @sem.limit
  end

  def test_semaphore_lock_with_custom_limit
    @sem = DaemonRunner::Semaphore.lock(@service, 1)
    assert_equal 1, @sem.limit
  end

  def test_can_check_semaphore_locked_state
    @sem1 = DaemonRunner::Semaphore.lock(@service, 1)
    @sem2 = DaemonRunner::Semaphore.lock(@service, 1)

    assert_equal true, @sem1.locked?
    assert_equal false, @sem2.locked?

    @sem1.release
    @sem2.lock

    assert_equal false, @sem1.locked?
    assert_equal true, @sem2.locked?
  end

  def test_semaphore_lock_waits_to_yield
    lock_checks = 0
    lock_checker = lambda do
      lock_checks += 1
      lock_checks >= 3
    end

    mock_semaphore = MockSemaphore.new(lock_check: lock_checker)

    DaemonRunner::Semaphore.stub :new, mock_semaphore do
      DaemonRunner::Semaphore.lock(@service, 1) do
        assert_equal 3, lock_checks
      end
    end

    assert_equal [
      :lock,
      :locked?, :try_lock,
      :locked?, :try_lock,
      :locked?,
      :renew,
      :release
    ], mock_semaphore.callstack
  end

  def test_can_get_two_uniq_lock_sessions
    @service1 = service_name
    @service2 = service_name

    @sem1 = DaemonRunner::Semaphore.lock(@service1)
    @sem2 = DaemonRunner::Semaphore.lock(@service2)

    refute_equal @sem1.session.id, @sem2.session.id
  end
end
