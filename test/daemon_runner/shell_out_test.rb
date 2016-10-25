require_relative '../test_helper'

class TestShellOut < ::DaemonRunner::ShellOut
  def command
    'echo 1'
  end

  def cwd
    '/'
  end

  def timeout
    150
  end
end

class ShellOutTest < Minitest::Test
  def test_can_run_new_command
    @cmd = ::DaemonRunner::ShellOut.new(command: 'echo 2')
    @cmd.run!
    assert_equal '2', @cmd.stdout.chomp
  end

  def test_can_run_command
    @cmd = ::TestShellOut.new
    @cmd.run!
    assert_equal '1', @cmd.stdout.chomp
  end

  def test_can_run_new_cwd
    @cmd = ::DaemonRunner::ShellOut.new(command: 'echo 2', cwd: '/home')
    @cmd.run!
    assert_equal '/home', @cmd.cwd
  end

  def test_can_run_cwd
    @cmd = ::TestShellOut.new
    @cmd.run!
    assert_equal '/', @cmd.cwd
  end

  def test_can_run_new_timeout
    @cmd = ::DaemonRunner::ShellOut.new(command: 'echo 2', cwd: '/tmp', timeout: 250)
    @cmd.run!
    assert_equal 250, @cmd.timeout
  end

  def test_can_run_timeout
    @cmd = ::TestShellOut.new
    @cmd.run!
    assert_equal 150, @cmd.timeout
  end

  def test_can_run_new_nowait
    @cmd = ::DaemonRunner::ShellOut.new(command: 'ping -c 10 localhost',
                                        cwd: '/tmp',
                                        timeout: 250,
                                        wait: false)
    @cmd.run!
    assert_equal false, @cmd.wait
  end

  def test_can_run_wait
    @cmd = ::TestShellOut.new
    @cmd.run!
    assert_equal true, @cmd.wait
  end

  def test_returns_pid_for_nowait
    @cmd = ::DaemonRunner::ShellOut.new(command: 'ping -c 10 localhost',
                                        cwd: '/tmp',
                                        timeout: 250,
                                        wait: false)
    pid = @cmd.run!
    assert_kind_of Fixnum, pid
  end

  def test_returns_mixlib_shellout_for_wait
    @cmd = ::TestShellOut.new
    shellout = @cmd.run!
    assert_kind_of Mixlib::ShellOut, shellout
  end

  def test_defaults_to_zero_for_valid_exit_codes
    @cmd = ::TestShellOut.new
    shellout = @cmd.run!
    assert_equal [0], shellout.valid_exit_codes
  end

  def test_allows_custom_valid_exit_codes
    @cmd = ::DaemonRunner::ShellOut.new(command: 'exit 1',
                                        valid_exit_codes: [1])
    shellout = @cmd.run!
    assert_equal [1], shellout.valid_exit_codes
  end

  def test_returns_nil_if_waiting_without_child_process
    wait2 = lambda { |pid, flags| raise Errno::ECHILD }

    Process.stub :wait2, wait2 do
      result = ::DaemonRunner::ShellOut.wait2(2600)
      assert_equal nil, result
    end
  end

  def test_returns_nil_if_pid_is_not_provided
    result = ::DaemonRunner::ShellOut.wait2
    assert_equal nil, result
  end

  def test_wait2_tracks_running_process
    @cmd = ::DaemonRunner::ShellOut.new(command: 'exit 255',
                                        valid_exit_codes: [255],
                                        wait: false)
    @cmd.run!
    result = @cmd.wait2
    assert_equal 255, result.exitstatus
  end
end
