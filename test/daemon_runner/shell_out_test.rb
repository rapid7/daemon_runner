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
end
