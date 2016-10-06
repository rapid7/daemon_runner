require 'mixlib/shellout'

module DaemonRunner
  class ShellOut
    attr_reader :runner, :stdout
    attr_reader :command, :cwd, :timeout, :wait

    # @param command [String] the command to run
    # @param cwd [String] the working directory to run the command
    # @param timeout [Fixnum] the command timeout
    # @param wait [Boolean] wheather to wait for the command to finish
    def initialize(command: nil, cwd: '/tmp', timeout: 15, wait: true)
      @command = command
      @cwd = cwd
      @timeout = timeout
      @wait = wait
    end

    # Run command
    # @return [Mixlib::ShellOut, Fixnum] mixlib shellout client or a pid depending on the value of {#wait}
    def run!
      validate_command
      if wait
        run_and_wait
      else
        run_and_detach
      end
    end

    private

    # Run a command and wait for it to finish
    # @return [Mixlib::ShellOut] client
    def run_and_wait
      validate_args
      runner
      @runner.run_command
      @runner.error!
      @stdout = @runner.stdout
      @runner
    end

    # Run a command in a new process group, thus ignoring any furthur
    # updates about the status of the process
    # @return [Fixnum] process id
    def run_and_detach
      log_r, log_w = IO.pipe
      Process.spawn(command, pgroup: true, err: :out, out: log_w)
      log_r.close
      log_w.close
    end

    # Validate command is defined before trying to start the command
    # @ raise [ArgumentError] if any of the arguments are missing
    def validate_command
      if @command.nil? && !respond_to?(:command)
        raise ArgumentError, 'Must pass a command or implement a command method'
      end
    end

    # Validate arguments before trying to start the command
    # @ raise [ArgumentError] if any of the arguments are missing
    def validate_args
      if @cwd.nil? && !respond_to?(:cwd)
        raise ArgumentError, 'Must pass a cwd or implement a cwd method'
      end

      if @timeout.nil? && !respond_to?(:timeout)
        raise ArgumentError, 'Must pass a timeout or implement a timeout method'
      end
    end

    # Setup a new Mixlib::ShellOut client runner
    # @return [Mixlib::ShellOut] client
    def runner
      @runner ||= Mixlib::ShellOut.new(command, :cwd => cwd, :timeout => timeout)
    end
  end
end
